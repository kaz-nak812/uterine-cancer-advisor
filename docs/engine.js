// 子宮体癌 術後治療判定エンジン — ESGO–ESTRO–ESP 2025 (Lancet Oncol 2025;26:e423) / FIGO 2023
// ICI（術後補助）は国内保険適応外のため、主推奨は2021版（ESGO/ESTRO/ESP 2020）と同一内容、2025版ICIは補足表示。
(function () {
  const ND = ['nd', '未実施'];
  const NODE = [['neg', '陰性'], ['itc', 'ITC'], ['mic', '微小転移'], ['mac', '肉眼的転移'], ['img', '省略（画像陰性）'], ['imgpos', '画像で転移疑い（病理未確認）'], ['nx', '未評価']];
  const lowGrade = s => s.hist === 'endo' && (s.grade === '1' || s.grade === '2');
  const FIELDS = [
    { key: 'pole', step: 1, label: 'POLE 変異解析', sub: 'エキソヌクレアーゼドメインの病的変異', opts: [['mut', '病的変異あり'], ['wt', '変異なし'], ND] },
    { key: 'mmr', step: 1, label: 'MMR 免疫染色', sub: 'MLH1 / PMS2 / MSH2 / MSH6', opts: [['d', '欠損（dMMR）'], ['p', '保持（pMMR）'], ND] },
    { key: 'p53', step: 1, label: 'p53 免疫染色', sub: '過剰発現・null・細胞質型＝異常', opts: [['abn', '異常型'], ['wt', '野生型'], ND] },
    { key: 'er', step: 1, label: 'ER 免疫染色', sub: '陽性＝10%以上', opts: [['pos', '陽性'], ['neg', '陰性'], ND] },
    { key: 'hist', step: 2, label: '組織型', opts: [['endo', '類内膜癌'], ['serous', '漿液性癌'], ['clear', '明細胞癌'], ['cs', '癌肉腫'], ['undiff', '未分化・脱分化癌'], ['mixed', '混合癌'], ['other', 'その他高悪性度']] },
    { key: 'grade', step: 2, label: 'Grade', sub: 'G1–2＝低異型度、G3＝高異型度', show: s => s.hist === 'endo', opts: [['1', 'G1'], ['2', 'G2'], ['3', 'G3']] },
    { key: 'mi', step: 2, label: '筋層浸潤', opts: [['0', 'なし'], ['lt', '1/2未満'], ['ge', '1/2以上']] },
    { key: 'lvsi', step: 2, label: 'LVSI', sub: 'substantial＝WHO基準（≥5脈管）', opts: [['none', 'なし'], ['focal', 'focal'], ['sub', 'substantial']] },
    { key: 'cervix', step: 2, label: '頸部間質浸潤', opts: [['no', 'なし'], ['yes', 'あり']] },
    { key: 'ext', step: 2, multi: true, optional: true, label: '子宮外進展', sub: '該当をすべて選択（なければ未選択）', opts: [['adnexa', '付属器'], ['serosa', '漿膜・漿膜下'], ['vagina', '腟・傍子宮'], ['pelvperi', '骨盤腹膜'], ['mucosa', '膀胱・腸管粘膜'], ['abdperi', '骨盤外腹膜'], ['distant', '遠隔転移']] },
    { key: 'ia3', step: 2, label: '卵巣病変：IA3基準', sub: '低異型度類内膜・筋層浸潤1/2未満・LVSIなし・卵巣pT1a', show: s => (s.ext || []).includes('adnexa') && lowGrade(s) && s.mi !== 'ge' && s.lvsi === 'none', opts: [['yes', '満たす'], ['no', '満たさない']] },
    { key: 'pln', step: 2, label: '骨盤リンパ節', sub: 'SLN超微細検索を含む', opts: NODE },
    { key: 'paln', step: 2, label: '傍大動脈リンパ節', opts: NODE },
    { key: 'resid', step: 2, label: '術後残存腫瘍', opts: [['no', 'なし'], ['yes', 'あり']] },
    { key: 'age', step: 2, optional: true, label: '年齢', sub: '中リスク群の判断に使用', opts: [['lt60', '60歳未満'], ['ge60', '60歳以上']] },
    { key: 'her2', step: 2, optional: true, label: 'HER2', sub: '進行・再発の漿液性癌・癌肉腫・p53abnで考慮（IV, C）。国内は保険承認前', show: s => ['serous', 'cs'].includes(s.hist) || s.p53 === 'abn', opts: [['neg', '0〜1+'], ['eq', '2+'], ['pos', '3+／ISH陽性'], ND] },
  ];
  const RISK = {
    LOW: { label: '低リスク', en: 'LOW', rr: '5年再発リスク <8%', rank: 0 },
    UNC_E: { label: 'リスク不確定', en: 'UNCERTAIN', rr: 'データ不十分（低リスクよりやや高い可能性）', rank: 1 },
    INT: { label: '中リスク', en: 'INTERMEDIATE', rr: '5年再発リスク 8–14%', rank: 2 },
    HIR: { label: '高中間リスク', en: 'HIGH–INTERMEDIATE', rr: '5年再発リスク 15–24%', rank: 3 },
    UNC_A: { label: 'リスク不確定', en: 'UNCERTAIN', rr: 'III–IVA期 POLEmut：データ不十分', rank: 4 },
    HIGH: { label: '高リスク', en: 'HIGH', rr: '5年再発リスク ≥25%', rank: 5 },
    ADV: { label: '進行・転移／残存あり', en: 'ADVANCED', rr: '全身療法を中心に検討', rank: 6 },
  };
  const MOL = {
    POLE: { label: 'POLEmut', short: 'POLEmut' },
    MMRd: { label: 'MMRd', short: 'MMRd' },
    NSMP_L: { label: 'NSMP 低異型度・ER陽性', short: 'NSMP' },
    NSMP_H: { label: 'NSMP 高異型度またはER陰性', short: 'NSMP' },
    P53: { label: 'p53abn', short: 'p53abn' },
  };
  const pick = (v, a, b) => (v === a ? [a] : v === b ? [b] : [a, b]);

  function molCands(s) {
    if (s.pole === 'mut') return ['POLE'];
    const c = [];
    if (s.pole === 'nd') c.push('POLE');
    pick(s.mmr, 'd', 'p').forEach(m => {
      if (m === 'd') { c.push('MMRd'); return; }
      pick(s.p53, 'abn', 'wt').forEach(p => {
        if (p === 'abn') { c.push('P53'); return; }
        if (s.hist && !lowGrade(s)) { c.push('NSMP_H'); return; }
        pick(s.er, 'pos', 'neg').forEach(e => c.push(e === 'pos' ? (s.hist ? 'NSMP_L' : 'NSMP_?') : 'NSMP_H'));
      });
    });
    return [...new Set(c.map(x => (x === 'NSMP_?' ? 'NSMP_L' : x)))];
  }

  function molLive(s) {
    if (!s.pole || !s.mmr || !s.p53 || !s.er) return { state: 'empty', label: '未入力の検査があります' };
    if (s.pole === 'mut') return { state: 'definite', label: 'POLEmut', cls: 'POLE' };
    const c = molCands(s);
    if (c.length === 1) {
      const k = c[0];
      if (k.startsWith('NSMP') && !s.hist) return { state: 'definite', label: 'NSMP（亜分類は組織型・Gradeで決定）', cls: 'NSMP_L' };
      return { state: 'definite', label: MOL[k].label, cls: k };
    }
    return { state: 'provisional', label: '暫定：' + [...new Set(c.map(k => MOL[k].short))].join(' / ') + ' の可能性', cls: null };
  }

  function stage(s) {
    const ext = s.ext || [];
    const agg = !lowGrade(s);
    const r = (code, level) => ({ code, level });
    if (ext.includes('distant')) return r('IVC', 'IVB');
    if (ext.includes('abdperi')) return r('IVB', 'IVB');
    if (ext.includes('mucosa')) return r('IVA', 'IVA');
    if (s.paln === 'mac') return r('IIIC2ii', 'III');
    if (s.paln === 'mic') return r('IIIC2i', 'III');
    if (s.paln === 'imgpos') return { code: 'IIIC2', level: 'III', suspect: true };
    if (s.pln === 'mac') return r('IIIC1ii', 'III');
    if (s.pln === 'mic') return r('IIIC1i', 'III');
    if (s.pln === 'imgpos') return { code: 'IIIC1', level: 'III', suspect: true };
    if (ext.includes('pelvperi')) return r('IIIB2', 'III');
    if (ext.includes('vagina')) return r('IIIB1', 'III');
    if (ext.includes('serosa')) return r('IIIA2', 'III');
    if (ext.includes('adnexa') && !(s.ia3 === 'yes' && !agg)) return r('IIIA1', 'III');
    if (ext.includes('adnexa')) return r('IA3', 'I', 'ia3');
    if (agg) return s.mi === '0' && s.cervix === 'no' && s.lvsi !== 'sub' ? r('IC', 'I') : r('IIC', 'II');
    if (s.lvsi === 'sub') return r('IIB', 'II');
    if (s.cervix === 'yes') return r('IIA', 'II');
    if (s.mi === 'ge') return r('IB', 'I');
    if (s.mi === 'lt') return r('IA2', 'I');
    return r('IA1', 'I');
  }

  function row(s, st) {
    if (s.lvsi === 'sub') return 'sub';
    if (s.cervix === 'yes') return 'cervix';
    if (st.code === 'IA3') return 'ia3';
    return s.mi === '0' ? 'none' : s.mi;
  }

  function risk25(cls, st, s) {
    if (st.level === 'IVB' || (s.resid === 'yes' && (st.level === 'III' || st.level === 'IVA'))) return 'ADV';
    if (st.level === 'III' || st.level === 'IVA') return cls === 'POLE' ? 'UNC_A' : 'HIGH';
    if (s.resid === 'yes') return 'ADV';
    if (cls === 'POLE') return 'LOW';
    const rw = row(s, st);
    if (cls === 'P53' || cls === 'NSMP_H') return rw === 'none' ? 'UNC_E' : 'HIGH';
    if (cls === 'NSMP_L') return { none: 'LOW', lt: 'LOW', ia3: 'LOW', ge: 'INT', cervix: 'INT', sub: 'HIR' }[rw];
    const agg = !lowGrade(s);
    return { none: 'LOW', lt: agg ? 'INT' : 'LOW', ia3: 'LOW', ge: 'INT', cervix: 'HIR', sub: 'HIR' }[rw];
  }

  function risk2020(s) {
    const ext = s.ext || [];
    const nodes = ['mic', 'mac', 'imgpos'].includes(s.pln) || ['mic', 'mac', 'imgpos'].includes(s.paln);
    let lv = 'I';
    if (ext.includes('distant') || ext.includes('abdperi')) lv = 'IVB';
    else if (ext.includes('mucosa')) lv = 'IVA';
    else if (nodes || ext.length) lv = 'III';
    else if (s.cervix === 'yes') lv = 'II';
    if (lv === 'IVB' || (s.resid === 'yes' && lv !== 'I' && lv !== 'II')) return 'ADV';
    if (lv === 'III' || lv === 'IVA') return 'HIGH';
    if (s.hist !== 'endo') return lv === 'I' && s.mi === '0' ? 'INT' : 'HIGH';
    if (lv === 'II' || s.lvsi === 'sub') return 'HIR';
    const g3 = s.grade === '3';
    if (s.mi === 'ge') return g3 ? 'HIR' : 'INT';
    return g3 ? 'INT' : 'LOW';
  }

  const VBT = [['線量', 'HDR 21 Gy／3回（7 Gy/回）が最も一般的'], ['範囲', '21–24 Gy／3–4回、腟粘膜面から深さ5 mmで処方'], ['照射部位', '腟上部1/3〜1/2'], ['EBRT後の追加時', '8–11 Gy／2–3回']];
  const EBRT = [['線量', '45–48.6 Gy／25–27回（1.8 Gy/回、週5回）'], ['照射野', '骨盤（総腸骨〜閉鎖・内外腸骨、腟上部・傍腟組織）'], ['頸部間質浸潤例', 'VBTブースト追加を考慮（8–11 Gy／2–3回）']];
  const pN0 = s => ['neg', 'itc'].includes(s.pln) && ['neg', 'itc', 'img', 'nx'].includes(s.paln);
  const pNX = s => ['img', 'nx'].includes(s.pln);

  function recs(rk, ctx, s) {
    const lg = lowGrade(s);
    switch (rk) {
      case 'LOW': return [{ t: '術後補助療法なし', g: 'II, A', hl: true }];
      case 'UNC_E': return [{ t: '補助療法は一般に推奨されない', g: 'IV, C', n: '再発リスクは低リスク群よりやや高い可能性があるがデータ不十分', hl: true }];
      case 'INT': return [
        { t: '腟腔内照射（VBT）を考慮', g: 'I, A', trials: 'PORTEC-2', hl: !(s.age === 'lt60' || lg), dose: VBT },
        { t: '補助療法なしも選択肢', g: 'III, C', n: '特に60歳未満または低異型度（II, A）', hl: s.age === 'lt60' || lg },
      ];
      case 'HIR': return [
        { t: '骨盤外照射（EBRT）', g: 'II, A', n: pNX(s) ? '骨盤内制御のため推奨｜骨盤リンパ節が病理学的に未評価（pNX）のため、VBT単独・経過観察は根拠が弱い' : '骨盤内制御のため推奨', trials: 'PORTEC-1 / GOG-99', hl: true, dose: EBRT },
        { t: '腟腔内照射（VBT）', g: 'II, B', n: '代替選択肢。特にリンパ節評価済みでpN0', hl: pN0(s), dose: VBT },
        { t: '補助療法なしを考慮可', g: 'IV, B', n: 'pN0・substantial LVSIなし・低異型度の場合', hl: pN0(s) && s.lvsi !== 'sub' && lg },
      ];
      case 'HIGH': {
        const r = [
          { t: 'EBRT＋同時・補助化学療法（化学放射線療法）', g: 'I, A', n: '放射線とシスプラチンを同時に行い、終了後にCBDCA＋PTXを追加', trials: 'PORTEC-3', hl: true,
            dose: [['EBRT', '48.6 Gy／27回（1.8 Gy/回、週5回）'], ['同時併用', 'CDDP 50 mg/m²　照射1週目・4週目（day 1, 22）'], ['照射後', 'CBDCA AUC5＋PTX 175 mg/m²　3週毎 4コース']] },
          { t: '化学療法と放射線療法を順番に行う（逐次併用）', g: 'I, B', n: '同時併用ではなく、EBRTの前または後にプラチナ併用化学療法を行う方法。化学療法→EBRT→化学療法の「サンドイッチ法」もある', trials: 'NSGO-EC-9501/EORTC-55991・MaNGO ILIADE-III（統合解析）',
            dose: [['EBRT', '45–48.6 Gy／25–27回（1.8 Gy/回）'], ['化学療法', 'プラチナ併用（CBDCA＋PTXなど）4コースをEBRTの前または後に'], ['順序', '化学療法→EBRT、EBRT→化学療法、またはサンドイッチ（3コース→EBRT→3コース）']] },
          { t: '化学療法（CBDCA＋PTX）± VBT', g: 'I, B', n: '代替選択肢', trials: 'GOG-258',
            dose: [['化学療法', 'CBDCA AUC5–6＋PTX 175 mg/m²　3週毎 6コース'], ['VBT併用時', '腟断端の再発リスクに応じて追加（線量はVBT単独と同様）']] },
        ];
        if (ctx.cls === 'P53') r[0].n += '｜PORTEC-3分子解析：p53abnでCRTの上乗せ効果が最大';
        if (ctx.cls === 'MMRd') r[0].n += '｜PORTEC-3分子解析：MMRdではCRTの上乗せは明らかでない';
        return r;
      }
      case 'UNC_A': return [
        { t: '確立した推奨なし（データ不十分）', g: '—' },
        { t: 'MDTで症例ごとに高リスク治療からのde-escalationを考慮', g: 'IV, B', hl: true },
      ];
      case 'ADV': {
        const mmrd = ctx.cls === 'MMRd';
        const r = [];
        if (s.mmr === 'nd') r.push({ t: 'MMR検査を優先：一次全身療法の選択がMMR状態で異なる', g: '—', hl: true });
        if (mmrd || s.mmr === 'nd') r.push({ t: 'CBDCA＋PTX＋ICI → ICI維持療法（dMMR）', g: 'I, A', trials: 'RUBY / NRG-GY018 / DUO-E', n: '国内：ペムブロリズマブ、デュルバルマブが進行・再発子宮体癌の1次治療で承認（2024年）', hl: mmrd });
        if (!mmrd) {
          r.push({ t: 'CBDCA＋PTX（非dMMR、急速増大・有症状）', g: 'I, A', hl: s.mmr !== 'nd' });
          r.push({ t: 'ICI＋化学療法 → ICI維持、またはデュルバルマブ＋化学療法 → デュルバルマブ＋オラパリブ維持', g: 'I, B', trials: 'NRG-GY018 / DUO-E' });
          if (s.her2 === 'pos') r.push({ t: 'HER2 3+でICI禁忌時：CBDCA＋PTX＋トラスツズマブ', g: 'II, B', n: '国内では子宮体癌に対する抗HER2療法は保険適応外（2026年10月時点）' });
          if (lg && s.er === 'pos') r.push({ t: '低異型度・ER陽性・低腫瘍量：黄体ホルモン療法', g: 'III, A' });
        }
        if (s.resid === 'yes') r.push({ t: '切除不能な残存リンパ節・骨盤内病変：EBRT（±全身療法）を検討', g: 'I, A', n: '残存部位の再切除可否を専門施設で評価（V, A）',
          dose: [['EBRT', '骨盤（±傍大動脈）45–48.6 Gy／25–27回'], ['ブースト', '残存リンパ節へ同時ブースト（SIB）で線量増加（IV, B）']] });
        return r;
      }
    }
    return [];
  }

  function compute(s) {
    const vis = FIELDS.filter(f => !f.show || f.show(s));
    const missing = vis.filter(f => !f.optional && s[f.key] == null).map(f => f.label);
    if (missing.length) return { ready: false, missing };
    const st = stage(s);
    const cands = molCands(s);
    const per = cands.map(c => ({ cls: c, risk: risk25(c, st, s) }));
    const worst = per.reduce((a, b) => (RISK[b.risk].rank > RISK[a.risk].rank ? b : a));
    const definite = cands.length === 1;
    const riskKeys = [...new Set(per.map(p => p.risk))];
    const main = worst;
    let stageLabel;
    const early = st.level === 'I' || st.level === 'II';
    if (definite) {
      if (early && main.cls === 'POLE') stageLabel = 'IAm POLEmut';
      else if (early && main.cls === 'P53' && s.mi !== '0') stageLabel = 'IICm p53abn';
      else stageLabel = st.code + 'm ' + MOL[main.cls].short;
    } else stageLabel = st.code;
    if (st.suspect) stageLabel += '（疑い）';
    const provisional = !definite || !!st.suspect;
    const mmrdPossible = cands.includes('MMRd');
    const ici = (st.level === 'III' || st.level === 'IVA') && s.resid !== 'yes' && mmrdPossible && main.risk === 'HIGH'
      ? { provisional: provisional || main.cls !== 'MMRd' } : null;

    const tests = [];
    const poleMatters = s.pole === 'nd' && riskKeys.length > 1;
    if (s.pole === 'nd') tests.push(poleMatters
      ? { t: 'POLE変異解析', n: 'POLEmutならリスク群が変わり補助療法のde-escalationが可能', strong: true }
      : { t: 'POLE変異解析は省略可', n: 'I期低リスクでは結果が治療方針に影響しない（IV, C）', strong: false });
    if (s.mmr === 'nd') tests.push({ t: 'MMR免疫染色', n: '分子分類に必須。Lynch症候群スクリーニングとして全例推奨（III, A）', strong: true });
    if (s.p53 === 'nd') tests.push({ t: 'p53免疫染色', n: '判定困難・不均一ならTP53シーケンス（IV, B）', strong: true });
    if (s.er === 'nd') tests.push({ t: 'ER免疫染色', n: cands.some(c => c.startsWith('NSMP')) && lowGrade(s) ? 'NSMPのリスク分類に必須（IV, A）' : '全例で推奨（IV, A）', strong: cands.some(c => c.startsWith('NSMP')) && lowGrade(s) });
    if (s.her2 === 'nd') tests.push({ t: 'HER2 免疫染色', n: '免疫染色で2+（弱〜中等度の陽性）の場合は、ISH法（FISH等）で遺伝子増幅の有無を確認（IV, C）。※国内では子宮体癌に対するHER2検査・抗HER2療法は保険承認前（2026年10月時点）', strong: false });

    const notes = [];
    if (s.pole === 'mut' && (s.mmr === 'd' || s.p53 === 'abn')) notes.push('複数分類子：POLEmutとして分類（IV, B）');
    else if (s.mmr === 'd' && s.p53 === 'abn') notes.push('複数分類子：MMRdとして分類（IV, B）');
    if (s.pln === 'itc' || s.paln === 'itc') notes.push('ITC（pN0(i+)）は病期を上げない。予後的意義は不明（IV, C）');
    if (s.pln === 'img' || s.paln === 'img') notes.push('リンパ節郭清・SLN省略（画像陰性）：病理学的にはpNX扱い。病期・リスクが過小評価の可能性');
    if (s.pln === 'nx' || s.paln === 'nx') notes.push('リンパ節未評価（pNX）：病期・リスクが過小評価の可能性');
    if (st.suspect) notes.push('画像上のリンパ節転移疑い（病理未確認）：' + st.code + '期の疑いとして暫定判定');
    if (st.code === 'IA3') notes.push('IA3：子宮内膜と卵巣の同時性低異型度類内膜癌');
    if (!definite) notes.push('分子分類未確定のため、可能性のある分類のうち最も高いリスクで暫定表示');

    const summary = vis.map(f => {
      const v = s[f.key];
      const txt = f.multi ? ((v || []).length ? f.opts.filter(o => v.includes(o[0])).map(o => o[1]).join('・') : 'なし') : v == null ? '—' : (f.opts.find(o => o[0] === v) || [])[1];
      return { k: f.label, v: txt, nd: v === 'nd' };
    });

    return {
      ready: true, st, stageLabel, definite, provisional, cands, per, main,
      molLabel: definite ? MOL[main.cls].label : cands.map(c => MOL[c].short).filter((x, i, a) => a.indexOf(x) === i).join(' / ') + '（未確定）',
      risk: main.risk, riskInfo: RISK[main.risk],
      recs: recs(main.risk, { cls: main.cls }, s),
      ici, tests, notes, summary, cp2020: risk2020(s),
      range: definite ? [] : per.map(p => ({ cls: MOL[p.cls].label, risk: p.risk, riskLabel: RISK[p.risk].label })),
    };
  }

  const ICI = {
    main: '国内の保険診療では、2021版（ESGO/ESTRO/ESP 2020）と同様に上記の化学療法／放射線療法を基本とする',
    title: '2025ガイドラインでは',
    body: 'III–IVA期 MMRd：化学療法＋免疫チェックポイント阻害薬（±EBRT）を考慮',
    g: 'II, B',
    trials: 'RUBY（dostarlimab）／ NRG-GY018（pembrolizumab）／ DUO-E（durvalumab）／ KEYNOTE-B21（術後補助 pembrolizumab：全体では無効、dMMRで改善を示唆）',
    caveat: '残存腫瘍のない術後補助療法としてのICI併用は国内保険適応外',
  };

  // ---- view-model builder shared by all visual variants ----
  function view(cmp, P) {
    const st = cmp.state;
    const s = st.s;
    const set = (k, v, multi) => cmp.setState(o => {
      const n = { ...o.s };
      if (multi) { const a = new Set(n[k] || []); a.has(v) ? a.delete(v) : a.add(v); n[k] = [...a]; }
      else n[k] = n[k] === v ? null : v;
      return { s: n };
    });
    const mk = f => {
      const answered = f.multi ? true : s[f.key] != null;
      return {
        key: f.key, label: f.label, sub: f.sub || '', hasSub: !!f.sub, multi: !!f.multi, answered,
        mark: answered ? P.doneMark : P.todoMark, markColor: answered ? P.doneColor : P.todoColor,
        opts: f.opts.map(([v, l]) => {
          const on = f.multi ? (s[f.key] || []).includes(v) : s[f.key] === v;
          const sty = P.opt(on, v === 'nd');
          return { label: l, on, nd: v === 'nd', onClick: () => set(f.key, v, f.multi), ...sty };
        }),
      };
    };
    const vis = FIELDS.filter(f => !f.show || f.show(s));
    const f1 = vis.filter(f => f.step === 1).map(mk);
    const f2 = vis.filter(f => f.step === 2).map(mk);
    const req2 = vis.filter(f => f.step === 2 && !f.optional);
    const done2 = req2.filter(f => s[f.key] != null).length;
    const done1 = f1.filter(f => f.answered).length;
    const ml = molLive(s);
    const r = compute(s);
    const rc = r.ready ? P.risk[r.risk] : P.risk.NONE;
    const step = st.step;
    const go = n => () => { cmp.setState({ step: n }); cmp.scrollTop && cmp.scrollTop(); };
    const anyND = ['pole', 'mmr', 'p53', 'er'].some(k => s[k] === 'nd');
    return {
      step1: step === 1, step2: step === 2, step3: step === 3,
      goStep1: go(1), goStep2: go(2), goStep3: go(3),
      next: go(Math.min(3, step + 1)), prev: go(Math.max(1, step - 1)),
      notFirst: step > 1, notLast: step < 3, isLast: step === 3,
      nextLabel: step === 1 ? '病理所見へ' : step === 2 ? '判定を見る' : '',
      tabs: [['分子分類', 1, done1 + '/4'], ['病理所見', 2, done2 + '/' + req2.length], ['判定', 3, r.ready ? '✓' : '—']].map(([l, n, c]) => ({ label: l, num: String(n), count: c, onClick: go(n), ...P.tab(step === n, n < step || (n === 3 && r.ready)) })),
      progress: [1, 2, 3].map(n => ({ bg: n <= step ? P.accent : P.track })),
      f1, f2, done1, done2, total2: req2.length,
      done1Text: done1 + ' / 4', done2Text: done2 + ' / ' + req2.length,
      molText: ml.label, molState: ml.state, molDefinite: ml.state === 'definite', molProvisional: ml.state === 'provisional', molEmpty: ml.state === 'empty',
      molBg: ml.state === 'definite' ? P.mol[ml.cls] : ml.state === 'provisional' ? P.warn : P.track,
      molFg: ml.state === 'empty' ? P.sub : P.onColor,
      molLegend: ['POLE', 'MMRd', 'NSMP', 'P53'].map(k => {
        const key = k === 'NSMP' ? 'NSMP_L' : k;
        const lit = ml.state === 'definite' ? (ml.cls === key || (k === 'NSMP' && (ml.cls || '').startsWith('NSMP'))) : ml.state === 'provisional' ? molCands(s).some(c => c === key || (k === 'NSMP' && c.startsWith('NSMP'))) : false;
        return { label: k === 'P53' ? 'p53abn' : k === 'POLE' ? 'POLEmut' : k, bg: lit ? P.mol[key] : P.track, fg: lit ? P.onColor : P.sub, op: lit ? '1' : '0.55' };
      }),
      anyND,
      ready: r.ready, notReady: !r.ready,
      missingText: r.ready ? '' : '未入力：' + r.missing.join('、'),
      missingCount: r.ready ? 0 : r.missing.length,
      stageLabel: r.ready ? r.stageLabel : '—',
      stageBase: r.ready ? r.st.code : '—',
      molLabel: r.ready ? r.molLabel : '—',
      provisional: r.ready && r.provisional,
      definite: r.ready && r.definite,
      riskLabel: r.ready ? r.riskInfo.label : '判定待ち',
      riskEn: r.ready ? r.riskInfo.en : 'PENDING',
      riskRR: r.ready ? r.riskInfo.rr : '必須項目をすべて入力してください',
      riskBg: rc.bg, riskFg: rc.fg, riskSoft: rc.soft,
      recs: r.ready ? r.recs.map((x, i) => ({ ...x, num: String(i + 1), hasN: !!x.n, hasTrials: !!x.trials, hasDose: !!x.dose, doseRows: (x.dose || []).map(([k, v]) => ({ k, v })), ...P.rec(!!x.hl) })) : [],
      hasIci: !!(r.ready && r.ici), iciProvisional: !!(r.ready && r.ici && r.ici.provisional), ici: ICI,
      tests: r.ready ? r.tests.map(t => ({ ...t, ...P.test(t.strong) })) : [],
      hasTests: r.ready && r.tests.length > 0,
      strongTests: r.ready && r.tests.some(t => t.strong),
      notes: r.ready ? r.notes.map(t => ({ t })) : [], hasNotes: r.ready && r.notes.length > 0,
      range: r.ready ? r.range.map(x => ({ ...x, dot: P.risk[x.risk].bg })) : [], hasRange: r.ready && r.range.length > 0,
      summary: r.ready ? r.summary.map(x => ({ ...x, vColor: x.nd ? P.warnInk : P.ink })) : [],
      cp2020: r.ready ? RISK[r.cp2020].label : '—', cp2020Dot: r.ready ? P.risk[r.cp2020].bg : P.track,
      lynch: s.mmr === 'd',
      lynchOpen: !!st.lynchOpen,
      openLynch: () => cmp.setState({ lynchOpen: true }),
      closeLynch: () => cmp.setState({ lynchOpen: false }),
      lynchSteps: LYNCH.map((x, i) => {
        const on = !!(st.lynchChk || {})[i];
        return { ...x, num: String(i + 1), on, mark: on ? '✓' : String(i + 1), ...(P.chk ? P.chk(on) : {}),
          onClick: () => cmp.setState(o => ({ lynchChk: { ...(o.lynchChk || {}), [i]: !on } })) };
      }),
      lynchDone: LYNCH.filter((x, i) => (st.lynchChk || {})[i]).length + ' / ' + LYNCH.length,
      showDisclaimer: !st.agreed,
      agree: () => { try { localStorage.setItem('ec-postop-nav-agreed-v1', '1'); } catch (e) {} cmp.setState({ agreed: true }); },
      openDisclaimer: () => cmp.setState({ agreed: false }),
      reset: () => cmp.setState({ s: {}, step: 1, lynchChk: {}, lynchOpen: false }),
    };
  }

  const LYNCH = [
    { t: '家族歴の聴取', n: '第1〜2度近親者の大腸癌・子宮体癌・卵巣癌・胃癌・尿路上皮癌など、発症年齢を含めて確認（改訂ベセスダ／アムステルダムII基準を参考）' },
    { t: '患者への説明と遺伝カウンセリング紹介', n: 'dMMRはLynch症候群の可能性を示す所見であることを説明し、遺伝カウンセリング外来へ紹介（III, B）' },
    { t: '生殖細胞系列遺伝学的検査を検討', n: 'MLH1 / MSH2 / MSH6 / PMS2 / EPCAM。欠損蛋白のパターンを検査部門・遺伝外来へ伝達' },
    { t: '診断確定時のサーベイランス', n: '大腸内視鏡による定期的サーベイランス、関連癌の評価。卵巣温存は行わない（IV, B）' },
    { t: '血縁者へのカスケード検査の案内', n: '病的バリアント確定時、血縁者への情報提供と発端者からの案内を支援' },
  ];

  const DEMO = { pole: 'nd', mmr: 'd', p53: 'wt', er: 'pos', hist: 'endo', grade: '3', mi: 'ge', lvsi: 'sub', cervix: 'no', ext: [], pln: 'mic', paln: 'neg', resid: 'no', age: 'ge60' };
  function initState(props) {
    let agreed = !!props.skipDisclaimer;
    if (!agreed) { try { agreed = localStorage.getItem('ec-postop-nav-agreed-v1') === '1'; } catch (e) {} }
    return { s: props.demo ? { ...DEMO } : {}, step: props.startStep || 1, agreed, lynchOpen: false, lynchChk: {} };
  }

  window.ECEngine = { FIELDS, RISK, MOL, compute, molLive, view, initState };
})();
