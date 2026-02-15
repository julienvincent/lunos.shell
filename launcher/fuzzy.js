.pragma library

function score(query, text) {
  if (!query || query.length === 0) {
    return 0;
  }
  if (!text) {
    return 0;
  }

  var q = String(query).toLowerCase();
  var t = String(text).toLowerCase();

  if (t.startsWith(q)) {
    return 1000 - Math.min(200, t.length);
  }

  var idx = t.indexOf(q);
  if (idx >= 0) {
    return 800 - Math.min(300, idx) - Math.min(200, t.length);
  }

  // Simple subsequence match.
  var qi = 0;
  var last_match = -1;
  var gap_penalty = 0;

  for (var ti = 0; ti < t.length && qi < q.length; ti++) {
    if (t[ti] === q[qi]) {
      if (last_match >= 0) {
        gap_penalty += Math.max(0, ti - last_match - 1);
      }
      last_match = ti;
      qi++;
    }
  }

  if (qi !== q.length) {
    return 0;
  }

  return 500 - Math.min(400, gap_penalty) - Math.min(200, t.length);
}
