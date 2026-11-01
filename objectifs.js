/* =====================================================================
   Objectifs à 1 an et à 3 ans — hexagone VO2 max, préhension, squat, RDL,
   développé couché, tractions. Module partagé par l'espace adhérent et
   l'espace coach (mêmes calculs des deux côtés).

   Valeurs mesurées :
   - VO2 max : estimée depuis l'AMRAP 20 min (indicative, voir vo2FromAmrap) ;
   - préhension : meilleure main ;
   - squat, RDL, développé couché : 1RM estimé depuis un test 5RM (Brzycki) ;
   - tractions : maximum de répétitions (même modalité d'un test à l'autre).
   Aucune donnée de poids de corps : chacun est comparé à lui-même.

   Objectif = point de départ × progression attendue, pour 32 séances par an :
   - progression de base d'un adulte peu entraîné à ~2 séances par semaine
     (~90 séances par an) : VO2 max +12 %/an, préhension +8 %, 1RM +25 %,
     tractions +3 répétitions ;
   - dose : 32 séances au lieu de ~90 → effet réduit (racine du rapport, × 0,6) ;
   - âge : progression un peu plus lente avec l'âge (−0,6 % par an après 35 ans,
     au plus −30 %), et déclin naturel à compenser (VO2 max −0,5 %/an de 40 à
     60 ans puis −1 %/an ; force et préhension −1 %/an après 50 ans) ;
   - sexe et niveau de départ (VO2 max, préhension) : plus on part bas par
     rapport aux valeurs habituelles pour son âge et son sexe, plus la marge de
     progression est grande ;
   - années 2 et 3 : progression plus lente (55 % puis 35 % de la première).
   Un objectif n'est jamais en dessous du point de départ : maintenir, c'est
   déjà réussir. Ce sont des repères, à ajuster à chaque personne.
   ===================================================================== */
(function (global) {
  const SEANCES_AN = 32, SEANCES_REF = 90;
  const DOSE = Math.sqrt(SEANCES_AN / SEANCES_REF);

  // Valeurs habituelles par âge (médianes approximatives, arrondies) :
  // VO2 max : registre FRIEND (Kaminsky et al., 2015) ; préhension : normes de Dodds et al. (2014).
  const VO2_REF = { H: [[25, 48], [35, 42.4], [45, 37.8], [55, 32.6], [65, 28.2], [75, 24.4]],
                    F: [[25, 37.6], [35, 30.9], [45, 27.9], [55, 24.4], [65, 21.4], [75, 19]] };
  const GRIP_REF = { H: [[25, 50], [35, 51], [45, 49], [55, 46], [65, 41], [75, 35]],
                     F: [[25, 31], [35, 31], [45, 30], [55, 27], [65, 24], [75, 21]] };
  function interp(tab, age) {
    if (age <= tab[0][0]) return tab[0][1];
    for (let i = 1; i < tab.length; i++) {
      if (age <= tab[i][0]) { const [a0, v0] = tab[i - 1], [a1, v1] = tab[i]; return v0 + (v1 - v0) * (age - a0) / (a1 - a0); }
    }
    return tab[tab.length - 1][1];
  }
  const refFor = (tab, age, sexe) => tab[sexe] ? interp(tab[sexe], age) : (interp(tab.H, age) + interp(tab.F, age)) / 2;
  const num = (x) => (x == null || x === '' || !isFinite(Number(x))) ? null : Number(x);
  const fr = (x) => String(x).replace('.', ',');
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

  /* 1RM estimé (Brzycki) : charge × 36 / (37 − répétitions), valable jusqu'à 10 répétitions. */
  const brzycki = (kg, reps) => { kg = num(kg); reps = num(reps); return kg > 0 && reps >= 1 && reps <= 10 ? Math.round(kg * 36 / (37 - reps) * 2) / 2 : null; };

  /* VO2 max estimée depuis l'AMRAP 20 min — INDICATIVE (méthode maison, non validée) :
     1) coût en oxygène du circuit : 8 MET pour un circuit vigoureux sans repos (Compendium des
        activités physiques, Ainsworth et al. 2011), proportionnel à la cadence (référence :
        24 répétitions par minute, environ 6 tours en 20 min), × 0,85 en No impact ;
     2) part de la VO2 max utilisée, d'après la FC moyenne en % de la FC max :
        %FC max = 0,64 × %VO2 max + 37 (Swain et al., 1994).
     VO2 max ≈ (MET × 3,5) ÷ part de la VO2 max utilisée. */
  function vo2FromAmrap(d, fcMax) {
    if (!d || (d.duree_min || 10) !== 20 || d.fc_amrap_valide === false) return null;
    const reps = num(d.amrap_reps_totales) != null ? num(d.amrap_reps_totales) : num(d.amrap_tours_complets) != null ? num(d.amrap_tours_complets) * 81 : null;
    let pct = num(d.intensite_pct);
    if (pct == null && num(d.fc_moy_amrap) && (num(d.fc_max_retenue) || fcMax)) pct = num(d.fc_moy_amrap) / (num(d.fc_max_retenue) || fcMax) * 100;
    if (!(reps > 0) || !(pct > 0)) return null;
    const met = 8 * (reps / 20) / 24 * (d.no_impact ? 0.85 : 1);
    const part = (Math.min(pct, 100) - 37) / 0.64 / 100;
    if (part < 0.35) return null;   // effort trop léger pour une estimation
    const v = met * 3.5 / Math.min(part, 1);
    return v >= 12 && v <= 75 ? Math.round(v * 2) / 2 : null;
  }

  const forceDecline = (a) => a < 50 ? 0 : 0.01;
  const AXES = [
    { key: 'vo2', label: 'VO2 max', unit: 'ml/kg/min', base: 0.12, round: 0.5, decline: (a) => a < 40 ? 0 : a < 60 ? 0.005 : 0.01,
      ref: (age, sx) => refFor(VO2_REF, age, sx), note: 'estimée depuis l’AMRAP, indicative' },
    { key: 'grip', label: 'Préhension', unit: 'kg', base: 0.08, round: 0.5, decline: forceDecline, ref: (age, sx) => refFor(GRIP_REF, age, sx), note: 'meilleure main' },
    { key: 'squat', label: 'Squat', unit: 'kg', base: 0.25, round: 1, decline: forceDecline, note: '1RM estimé' },
    { key: 'rdl', label: 'RDL', unit: 'kg', base: 0.25, round: 1, decline: forceDecline, note: '1RM estimé' },
    { key: 'dc', label: 'Développé couché', unit: 'kg', base: 0.25, round: 1, decline: forceDecline, note: '1RM estimé' },
    { key: 'tractions', label: 'Tractions', unit: 'rép.', base: 3, round: 1, reps: true, note: 'maximum, même modalité' },
  ];

  function axisValue(key, tests, fcMax) {
    tests = tests || {};
    const f = tests.force_max || {};
    switch (key) {
      case 'vo2': return vo2FromAmrap(tests.amrap_cardio, fcMax);
      case 'grip': { const d = tests.grip; if (!d) return null; const v = [num(d.force_main_gauche_kg), num(d.force_main_droite_kg)].filter(x => x > 0); return v.length ? Math.max(...v) : null; }
      case 'squat': return num(f.squat_1rm) || brzycki(f.squat_charge_kg, f.squat_reps);
      case 'rdl': return num(f.rdl_1rm) || brzycki(f.rdl_charge_kg, f.rdl_reps);
      case 'dc': return num(f.dc_1rm) || brzycki(f.dc_charge_kg, f.dc_reps);
      case 'tractions': return num(f.tractions_reps);
    }
    return null;
  }

  function objectives(ax, start, age, sexe) {
    if (start == null) return null;
    const a = Math.min(1, Math.max(0.7, 1 - 0.006 * Math.max(0, age - 35)));
    if (ax.reps) {
      const inc = Math.max(1, Math.round(ax.base * DOSE * a * (start < 5 ? 1 : 0.7)));
      return { y1: start + inc, y3: start + Math.round(inc * 2.2) };
    }
    const dec = ax.decline ? ax.decline(age) : 0;
    let f = 1;
    if (ax.ref) f = Math.min(1.4, Math.max(0.4, 1.6 - 0.6 * start / ax.ref(age, sexe)));
    const g = ax.base * DOSE * f * a;
    const y1 = start * (1 + g - dec), y2 = y1 * (1 + 0.55 * g - dec), y3 = y2 * (1 + 0.35 * g - dec);
    const rd = (x) => Math.round(Math.max(start, x) / ax.round) * ax.round;
    return { y1: rd(y1), y3: rd(Math.max(y3, y1)) };
  }

  /* byPt : { T0: { type_de_test: données }, T1: … } ; opts : { sexe, naissance (AAAA-MM-JJ), dates: { T0: 'AAAA-MM-JJ' }, fcMax: (pt) => nombre } */
  function compute(byPt, opts) {
    opts = opts || {};
    const pts = ['T0', 'T1', 'T2', 'T3'].filter(p => byPt && byPt[p]);
    const ageAt = (pt) => {
      if (!opts.naissance) return null;
      const d = (opts.dates && opts.dates[pt]) || new Date().toISOString().slice(0, 10);
      const [y, m, j] = opts.naissance.split('-').map(Number), [Y, M, J] = d.split('-').map(Number);
      return Y - y - ((M < m || (M === m && J < j)) ? 1 : 0);
    };
    return AXES.map(ax => {
      let vals = pts.map(pt => ({ pt, v: axisValue(ax.key, byPt[pt], opts.fcMax && opts.fcMax(pt)) })).filter(x => x.v != null);
      if (ax.key === 'tractions' && vals.length) {   // tractions : seulement la modalité du départ (sinon pas comparable)
        const mod = (p) => (byPt[p].force_max || {}).tractions_modalite || '';
        vals = vals.filter(x => mod(x.pt) === mod(vals[0].pt));
      }
      const first = vals[0], last = vals[vals.length - 1];
      const age = first ? (ageAt(first.pt) != null ? ageAt(first.pt) : 40) : null;
      const obj = first ? objectives(ax, first.v, age, opts.sexe) : null;
      const modalite = ax.key === 'tractions' && first ? (byPt[first.pt].force_max || {}).tractions_modalite : null;
      return { ax, start: first ? first.v : null, startPt: first && first.pt, last: last && last !== first ? last.v : null, lastPt: last && last !== first ? last.pt : null,
        y1: obj && obj.y1, y3: obj && obj.y3, age, modalite, sansAge: !opts.naissance };
    });
  }

  const COL = { y3: '#3E8E5A', y1: '#2F6FB0', start: '#8A9BB0', last: '#C26B4A' };
  function hexSvg(rows) {
    const W = 420, cx = 210, cy = 175, R = 120, n = rows.length;
    const ang = (i) => -Math.PI / 2 + i * 2 * Math.PI / n;
    const P = (i, c) => [cx + Math.cos(ang(i)) * R * c / 100, cy + Math.sin(ang(i)) * R * c / 100];
    const poly = (key, cls) => {
      const p = rows.map((r, i) => r.y3 && r[key] != null ? P(i, Math.max(3, Math.min(115, r[key] / r.y3 * 100))) : null).filter(Boolean);
      return p.length >= 3 ? '<polygon points="' + p.map(z => z.map(q => q.toFixed(1)).join(',')).join(' ') + '" class="' + cls + '"/>' : '';
    };
    let g = '';
    [25, 50, 75, 100].forEach(c => { g += '<polygon points="' + rows.map((_, i) => P(i, c).map(z => z.toFixed(1)).join(',')).join(' ') + '" class="hg"/>'; });
    rows.forEach((r, i) => {
      const [x, y] = P(i, 100), [lx, ly] = P(i, 124);
      g += '<line x1="' + cx + '" y1="' + cy + '" x2="' + x.toFixed(1) + '" y2="' + y.toFixed(1) + '" class="hg"/>' +
        '<text x="' + lx.toFixed(1) + '" y="' + (ly + 4).toFixed(1) + '" class="hl' + (r.start == null ? ' off' : '') + '">' + esc(r.ax.label) + '</text>';
    });
    // niveau actuel : dernière valeur mesurée de chaque qualité (le départ si elle n'a pas été retestée)
    rows.forEach(r => { r.cur = r.last != null ? r.last : r.start; });
    g += poly('y3', 'hy3') + poly('y1', 'hy1') + poly('start', 'hst') + (rows.some(r => r.last != null) ? poly('cur', 'hla') : '');
    return '<svg viewBox="0 0 ' + W + ' 350" class="hexa" role="img" aria-label="Hexagone des objectifs">' + g + '</svg>';
  }
  function legendHtml(rows) {
    const lastPt = (rows.find(r => r.lastPt) || {}).lastPt, startPt = (rows.find(r => r.startPt) || {}).startPt || 'T0';
    return '<p class="hexleg"><span style="color:' + COL.start + '">■</span> ' + startPt + ' (départ)' + (lastPt ? ' &nbsp; <span style="color:' + COL.last + '">■</span> aujourd’hui' : '') +
      ' &nbsp; <span style="color:' + COL.y1 + '">┅</span> objectif 1 an &nbsp; <span style="color:' + COL.y3 + '">■</span> objectif 3 ans</p>';
  }
  function tableHtml(rows) {
    const v = (x) => x == null ? '—' : fr(x);
    return '<div class="hexwrap"><table class="hextbl"><thead><tr><th>Qualité</th><th>Départ</th><th>Dernier</th><th>Objectif<br>1 an</th><th>Objectif<br>3 ans</th></tr></thead><tbody>' +
      rows.map(r => '<tr><td><b>' + esc(r.ax.label) + '</b> <span class="hexu">' + esc(r.ax.unit) + '</span><small>' + esc(r.ax.note) + (r.modalite ? ' · ' + esc(r.modalite) : '') + '</small></td>' +
        (r.start == null ? '<td colspan="4" class="hexoff">pas encore mesuré' + (r.ax.key === 'vo2' ? ' (AMRAP avec capteur cardiaque)' : r.ax.key === 'grip' ? '' : ' (tests de force max)') + '</td>'
          : '<td>' + v(r.start) + '<small>' + r.startPt + '</small></td><td>' + (r.last != null ? v(r.last) + '<small>' + r.lastPt + '</small>' : '—') + '</td>' +
            '<td class="hexo1">' + v(r.y1) + '</td><td class="hexo3">' + v(r.y3) + '</td>') + '</tr>').join('') + '</tbody></table></div>';
  }
  /* opts.coach : textes à la 3e personne (fiche du coach) ; sinon on tutoie l'adhérent. */
  function html(byPt, opts) {
    opts = opts || {};
    const rows = compute(byPt, opts), any = rows.filter(r => r.start != null).length, c = !!opts.coach;
    const ton = c ? 'son' : 'ton', ta = c ? 'la' : 'ta';
    if (!any) return '<p class="muted">' + (c ? 'Objectifs disponibles après un premier test' : 'Tes objectifs apparaîtront après ton premier test') +
      ' (AMRAP avec capteur, préhension, tests de force max).</p>';
    return (any >= 3 ? hexSvg(rows) + legendHtml(rows) : '<p class="muted">L’hexagone s’affiche dès que 3 qualités sont mesurées.</p>') + tableHtml(rows) +
      '<p class="note">Objectifs calculés pour <b>' + SEANCES_AN + ' séances par an</b>, selon ' + ton + ' point de départ, ' + ton + ' âge' +
      (rows[0].sansAge ? ' (inconnu : 40 ans par défaut)' : '') + ' et ' + ton + ' sexe. Maintenir son niveau en vieillissant, c’est déjà un progrès. ' +
      'VO2 max estimée depuis l’AMRAP : valeur indicative, pour suivre ' + ta + ' tendance. Chaque branche de l’hexagone est graduée par rapport à ' +
      ton + ' objectif à 3 ans (le grand hexagone vert).</p>';
  }
  const CSS = '.hexa{width:100%;max-width:440px;display:block;margin:0 auto}.hexa .hg{fill:none;stroke:#E2DACB;stroke-width:1}' +
    '.hexa .hl{font-size:12px;fill:#22302A;text-anchor:middle;font-weight:600}.hexa .hl.off{fill:#B9C1BB;font-weight:400}' +
    '.hexa .hy3{fill:' + COL.y3 + ';fill-opacity:.12;stroke:' + COL.y3 + ';stroke-width:2}.hexa .hy1{fill:none;stroke:' + COL.y1 + ';stroke-width:2;stroke-dasharray:6 4}' +
    '.hexa .hst{fill:' + COL.start + ';fill-opacity:.25;stroke:' + COL.start + ';stroke-width:2}.hexa .hla{fill:' + COL.last + ';fill-opacity:.18;stroke:' + COL.last + ';stroke-width:2.5}' +
    '.hexleg{text-align:center;font-size:.85rem;font-weight:600;margin:.2rem 0 .6rem}' +
    '.hexwrap{overflow-x:auto;-webkit-overflow-scrolling:touch}.hextbl{border-collapse:collapse;width:100%;font-size:.86rem;font-variant-numeric:tabular-nums}' +
    '.hextbl th,.hextbl td{padding:.4rem .35rem;border-bottom:1px solid #DDD4C3;text-align:right;vertical-align:top}.hextbl th:first-child,.hextbl td:first-child{text-align:left}' +
    '.hextbl thead th{font-size:.68rem;text-transform:uppercase;letter-spacing:.04em;color:#6E7B73;font-weight:700;line-height:1.25}' +
    '.hextbl small{display:block;color:#6E7B73;font-size:.7rem;font-weight:400}.hexu{color:#6E7B73;font-size:.72rem;font-weight:400}' +
    '.hexo1{color:' + COL.y1 + ';font-weight:700}.hexo3{color:' + COL.y3 + ';font-weight:700}.hexoff{color:#9AA39D;text-align:center!important}';
  if (typeof document !== 'undefined') { const st = document.createElement('style'); st.textContent = CSS; document.head.appendChild(st); }

  global.OBJECTIFS = { SEANCES_AN, AXES, brzycki, vo2FromAmrap, axisValue, objectives, compute, hexSvg, legendHtml, tableHtml, html };
})(typeof window !== 'undefined' ? window : globalThis);
