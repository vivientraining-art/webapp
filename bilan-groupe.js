/* =====================================================================
   Bilan du groupe — statistiques anonymes du cours et de l'association,
   calculées par la base (fonction stats_groupe, migration 17) : moyennes,
   écarts-types et part de progrès, jamais de valeur individuelle, et rien
   pour moins de 5 personnes. Pour se faire une idée générale, pas pour se
   comparer. Module partagé : espace adhérent (onglet Progression) et aperçu
   dans l'espace coach.
   ===================================================================== */
(function (global) {
  const IND = [
    ['prehension', 'Préhension (meilleure main)', 'kg'],
    ['pompes:genoux sans gainage', 'Pompes — genoux sans gainage', 'rép.'],
    ['pompes:genoux avec gainage', 'Pompes — genoux avec gainage', 'rép.'],
    ['pompes:jambes tendues', 'Pompes — jambes tendues', 'rép.'],
    ['wallsit', 'Wall-sit', 's'],
    ['amrap_tours', 'AMRAP 20 min — tours complets', 'tours'],
    ['amrap_intensite', 'AMRAP — intensité', '% FC max'],
    ['hrr60', 'Récupération — HRR60', 'bpm'],
    ['squat', 'Squat — 1RM estimé', 'kg'],
    ['dc', 'Développé couché — 1RM estimé', 'kg'],
    ['rdl', 'RDL — 1RM estimé', 'kg'],
  ];
  const fr = (x) => String(x).replace('.', ',');
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const label = (cle) => (IND.find(i => i[0] === cle) || [cle, cle.replace('pompes:', 'Pompes — '), ''])[1];
  const unit = (cle) => (IND.find(i => i[0] === cle) || [, , ''])[2];
  const order = (cle) => { const i = IND.findIndex(x => x[0] === cle); return i < 0 ? 99 : i; };

  function scopeHtml(d, scope, titre) {
    const st = (d.stats || []).filter(s => s.scope === scope), ev = (d.evolution || []).filter(e => e.scope === scope);
    if (!st.length && !ev.length) return '<h4 class="bgh">' + esc(titre) + '</h4><p class="bgvide">Pas encore assez de personnes testées pour afficher des statistiques (5 au minimum).</p>';
    const pts = [...new Set(st.map(s => s.pt))].sort(), cles = [...new Set(st.map(s => s.cle))].sort((a, b) => order(a) - order(b));
    let h = '<h4 class="bgh">' + esc(titre) + '</h4>';
    if (cles.length) h += '<div class="bgwrap"><table class="bgtbl"><thead><tr><th>Test</th>' + pts.map(p => '<th>' + p + '</th>').join('') + '</tr></thead><tbody>' +
      cles.map(c => '<tr><td>' + esc(label(c)) + ' <span class="bgu">' + esc(unit(c)) + '</span></td>' + pts.map(p => {
        const s = st.find(x => x.cle === c && x.pt === p);
        return '<td>' + (s ? '<span class="bgv"><b>' + fr(s.moyenne) + '</b>' + (s.ecart_type != null ? ' ± ' + fr(s.ecart_type) : '') + '</span><small>' + s.n + ' pers.</small>' : '—') + '</td>';
      }).join('') + '</tr>').join('') + '</tbody></table></div>';
    if (ev.length) h += '<ul class="bgevo">' + ev.sort((a, b) => order(a.cle) - order(b.cle)).map(e => {
      const pct = Math.round(e.progres / e.n * 100), v = Number(e.variation_moyenne);
      return '<li><b>' + esc(label(e.cle)) + '</b> : <span class="bgup">' + e.progres + ' sur ' + e.n + ' ont progressé (' + pct + ' %)</span>, ' +
        e.stable + ' stable' + (e.stable > 1 ? 's' : '') + (e.baisse ? ', ' + e.baisse + ' en baisse' : '') +
        ' · variation moyenne ' + (v > 0 ? '+' : v < 0 ? '−' : '±') + fr(Math.abs(v)) + ' ' + esc(unit(e.cle)) + '</li>';
    }).join('') + '</ul>';
    return h;
  }

  /* d : réponse de stats_groupe() ; opts.coach : textes pour l'aperçu du coach */
  function html(d, opts) {
    opts = opts || {};
    if (!d || !d.ouvert) return '';
    const parts = [];
    if (d.mon_cours) parts.push(scopeHtml(d, 'cours', 'Mon cours — ' + d.mon_cours));
    parts.push(scopeHtml(d, 'asso', 'Toute l’association'));
    return '<p class="bgintro">' + (opts.coach ? 'Ce que voient les adhérents : pour' : 'Pour') + ' te faire une idée générale — <b>pas pour se comparer</b> : ' +
      'chacun part de son niveau et progresse à son rythme. Chiffres anonymes : moyenne ± écart-type (environ 2 personnes sur 3 se situent dans cet ' +
      'intervalle), affichés seulement à partir de ' + (d.k_min || 5) + ' personnes.</p>' +
      '<p class="bglink"><a href="bilan-asso.html">Voir le niveau de toute l’association en une page →</a></p>' + parts.join('') +
      '<p class="bgnote">« Ont progressé » : progrès au-delà de la variabilité normale du test d’un jour à l’autre, entre le premier et le dernier test ' +
      'de chacun, dans les mêmes conditions. Pompes : chaque variante à part.</p>';
  }

  const CSS = '.bgintro{font-size:.86rem;line-height:1.5;color:#3F4D45;margin:0 0 .6rem}.bgh{font-size:.92rem;margin:.9rem 0 .4rem;color:#1F3A2D}' +
    '.bgwrap{overflow-x:auto;-webkit-overflow-scrolling:touch}.bgtbl{border-collapse:collapse;width:100%;font-size:.86rem;font-variant-numeric:tabular-nums}' +
    '.bgtbl th,.bgtbl td{padding:.4rem .35rem;border-bottom:1px solid #DDD4C3;text-align:right;vertical-align:top}.bgtbl th:first-child,.bgtbl td:first-child{text-align:left}' +
    '.bgtbl thead th{font-size:.68rem;text-transform:uppercase;letter-spacing:.04em;color:#6E7B73}.bgtbl small{display:block;color:#6E7B73;font-size:.7rem}' +
    '.bgv{white-space:nowrap}.bgu{color:#6E7B73;font-size:.72rem}.bgevo{margin:.5rem 0 0 1.1rem;font-size:.86rem;line-height:1.6}.bgup{color:#2F7D3D;font-weight:600}' +
    '.bglink{margin:0 0 .4rem;font-size:.9rem}.bglink a{color:#C26B4A;font-weight:600;text-decoration:none}.bgvide{font-size:.85rem;color:#6E7B73}.bgnote{font-size:.76rem;color:#6E7B73;line-height:1.5;margin-top:.6rem}';
  if (typeof document !== 'undefined') { const s = document.createElement('style'); s.textContent = CSS; document.head.appendChild(s); }

  global.BILAN_GROUPE = { html };
})(typeof window !== 'undefined' ? window : globalThis);
