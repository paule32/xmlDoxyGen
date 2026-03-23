/*
 @licstart  The following is the entire license notice for the JavaScript code in this file.

 The MIT License (MIT)

 Copyright (C) 1997-2026 by Dimitri van Heesch

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 and associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute,
 sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or
 substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
 BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 @licend  The above is the entire license notice for the JavaScript code in this file
 */
function toggleVisibility(linkObj) {
  return dynsection.toggleVisibility(linkObj);
}

/* ---------- shared helpers ---------- */
function _forEachNode(list, fn) {
  if (!list) return;
  for (var i = 0; i < list.length; i++) fn(list[i], i);
}

function _hasClass(el, cls) {
  if (!el) return false;
  if (el.classList) return el.classList.contains(cls);
  return (' ' + el.className + ' ').indexOf(' ' + cls + ' ') !== -1;
}

function _addClass(el, cls) {
  if (!el) return;
  if (el.classList) el.classList.add(cls);
  else if (!_hasClass(el, cls)) el.className += (el.className ? ' ' : '') + cls;
}

function _removeClass(el, cls) {
  if (!el) return;
  if (el.classList) el.classList.remove(cls);
  else el.className = (' ' + el.className + ' ')
    .replace(new RegExp('(^|\\s)' + cls + '(?=\\s|$)', 'g'), ' ')
    .replace(/\s+/g, ' ')
    .replace(/^\s+|\s+$/g, '');
}

function _replaceClass(el, fromClass, toClass) {
  if (_hasClass(el, fromClass)) {
    _removeClass(el, fromClass);
    _addClass(el, toClass);
  }
}

function _startsWith(str, prefix) {
  return str && str.substr(0, prefix.length) === prefix;
}

function _nextElementSibling(el) {
  if (!el) return null;
  if (el.nextElementSibling) return el.nextElementSibling;
  var n = el.nextSibling;
  while (n && n.nodeType !== 1) n = n.nextSibling;
  return n;
}

function _after(refNode, newNode) {
  if (!refNode || !newNode || !refNode.parentNode) return;
  if (refNode.nextSibling) refNode.parentNode.insertBefore(newNode, refNode.nextSibling);
  else refNode.parentNode.appendChild(newNode);
}

function _replaceWith(oldNode, newNode) {
  if (!oldNode || !newNode || !oldNode.parentNode) return;
  oldNode.parentNode.replaceChild(newNode, oldNode);
}

/* ---------- dynsection ---------- */
var dynsection = {

  updateStripes: function () {
    var rows = document.querySelectorAll('table.directory tr');

    // even/odd entfernen
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i];
      if (r.classList) {
        r.classList.remove('even');
        r.classList.remove('odd');
      } else {
        r.className = (' ' + r.className + ' ')
          .replace(/(^|\s)even(\s|$)/g, ' ')
          .replace(/(^|\s)odd(\s|$)/g, ' ')
          .replace(/\s+/g, ' ')
          .replace(/^\s+|\s+$/g, '');
      }
    }

    // nur sichtbare zebra-stripes setzen
    var visibleIndex = 0;
    for (i = 0; i < rows.length; i++) {
      var row = rows[i];
      if (row.offsetParent === null) continue;

      if (row.classList) {
        row.classList.add((visibleIndex % 2 === 0) ? 'even' : 'odd');
      } else {
        if (!_hasClass(row, (visibleIndex % 2 === 0) ? 'even' : 'odd')) {
          row.className += (row.className ? ' ' : '') + ((visibleIndex % 2 === 0) ? 'even' : 'odd');
        }
      }
      visibleIndex++;
    }
  },

  slide: function (element, fromHeight, toHeight, duration) {
    if (duration == null) duration = 200;
    if (!element) return;

    element.style.overflow = 'hidden';
    element.style.transition = 'height ' + duration + 'ms ease-out';
    element.style.webkitTransition = 'height ' + duration + 'ms ease-out';
    element.style.height = fromHeight;

    // Reflow hilft in älteren Browsern
    element.offsetHeight;

    setTimeout(function () {
      element.style.height = toHeight;

      setTimeout(function () {
        element.style.height = '';
        element.style.transition = '';
        element.style.webkitTransition = '';
        element.style.overflow = '';
        if (toHeight === '0px') element.style.display = 'none';
      }, duration);
    }, 0);
  },

  toggleVisibility: function (linkObj) {
    var base = linkObj.getAttribute('id');
    var summary = document.getElementById(base + '-summary');
    var content = document.getElementById(base + '-content');
    // trigger/src bleiben drin, falls du es später brauchst
    var trigger = document.getElementById(base + '-trigger');
    var src = trigger ? trigger.getAttribute('src') : null;

    var arrows = linkObj.querySelectorAll ? linkObj.querySelectorAll('.arrowhead') : [];
    var i, el;

    if (content && content.offsetParent !== null) {
      var height = content.offsetHeight;
      this.slide(content, height + 'px', '0px');

      if (summary) summary.style.display = '';

      for (i = 0; i < arrows.length; i++) {
        el = arrows[i];
        _addClass(el, 'closed');
        _removeClass(el, 'opened');
      }
    } else {
      if (!content) return false;

      content.style.display = 'block';
      var h = content.scrollHeight;
      this.slide(content, '0px', h + 'px');

      if (summary) summary.style.display = 'none';

      for (i = 0; i < arrows.length; i++) {
        el = arrows[i];
        _removeClass(el, 'closed');
        _addClass(el, 'opened');
      }
    }

    return false;
  },

  toggleLevel: function (level) {
    var self = this;
    var rows = document.querySelectorAll('table.directory tr');

    _forEachNode(rows, function (row) {
      if (!row.id) return;

      var l = row.id.split('_').length - 1;
      var suffix = row.id.substring(3);
      var iEl = document.getElementById('img' + suffix);
      var aEl = document.getElementById('arr' + suffix);

      if (l < level + 1) {
        if (iEl && iEl.querySelectorAll) {
          _forEachNode(iEl.querySelectorAll('.folder-icon'), function (el) { _addClass(el, 'open'); });
        }
        if (aEl && aEl.querySelectorAll) {
          _forEachNode(aEl.querySelectorAll('.arrowhead'), function (el) {
            _removeClass(el, 'closed');
            _addClass(el, 'opened');
          });
        }
        row.style.display = '';

      } else if (l === level + 1) {
        if (aEl && aEl.querySelectorAll) {
          _forEachNode(aEl.querySelectorAll('.arrowhead'), function (el) {
            _removeClass(el, 'opened');
            _addClass(el, 'closed');
          });
        }
        if (iEl && iEl.querySelectorAll) {
          _forEachNode(iEl.querySelectorAll('.folder-icon'), function (el) { _removeClass(el, 'open'); });
        }
        row.style.display = '';

      } else {
        row.style.display = 'none';
      }
    });

    self.updateStripes();
  },

  toggleFolder: function (id) {
    var self = this;

    var currentRow = document.getElementById('row_' + id);
    if (!currentRow) return;

    // alle TRs nach currentRow sammeln (nextElementSibling -> nextSibling loop)
    var rows = [];
    var nextRow = currentRow.nextSibling;
    while (nextRow) {
      if (nextRow.nodeType === 1) {
        if (nextRow.tagName === 'TR') rows.push(nextRow);
        else break;
      }
      nextRow = nextRow.nextSibling;
    }

    var re = new RegExp('^row_' + id + '\\d+_$', 'i'); // only one sub

    // childRows filtern (ohne Array.filter)
    var childRows = [];
    for (var i = 0; i < rows.length; i++) {
      if (re.test(rows[i].id)) childRows.push(rows[i]);
    }
    if (childRows.length === 0) return;

    // first row visible => HIDING
    if (childRows[0].offsetParent !== null) {
      var currentRowSpans = currentRow.getElementsByTagName('span');
      _forEachNode(currentRowSpans, function (span) {
        if (_hasClass(span, 'iconfolder') && span.querySelectorAll) {
          _forEachNode(span.querySelectorAll('.folder-icon'), function (el) { _removeClass(el, 'open'); });
        }
        _replaceClass(span, 'opened', 'closed');
      });

      // hide all children
      var prefix = 'row_' + id;
      for (i = 0; i < rows.length; i++) {
        if (_startsWith(rows[i].id, prefix)) rows[i].style.display = 'none';
      }

    } else {
      // SHOWING
      var currentRowSpans2 = currentRow.getElementsByTagName('span');
      _forEachNode(currentRowSpans2, function (span) {
        if (_hasClass(span, 'iconfolder') && span.querySelectorAll) {
          _forEachNode(span.querySelectorAll('.folder-icon'), function (el) { _addClass(el, 'open'); });
        }
        _replaceClass(span, 'closed', 'opened');
      });

      // child rows anzeigen, deren eigene folder-icons zuklappen
      for (i = 0; i < childRows.length; i++) {
        var row = childRows[i];
        var childRowSpans = row.getElementsByTagName('span');

        _forEachNode(childRowSpans, function (span) {
          if (_hasClass(span, 'iconfolder') && span.querySelectorAll) {
            _forEachNode(span.querySelectorAll('.folder-icon'), function (el) { _removeClass(el, 'open'); });
          }
          _replaceClass(span, 'opened', 'closed');
        });

        row.style.display = '';
      }
    }

    self.updateStripes();
  },

  toggleInherit: function (id) {
    var rows = document.querySelectorAll('tr.inherit.' + id);
    var header = document.querySelector('tr.inherit_header.' + id);

    var isVisible = (rows.length > 0 && rows[0].offsetParent !== null);

    if (isVisible) {
      _forEachNode(rows, function (row) { row.style.display = 'none'; });

      if (header) {
        _forEachNode(header.querySelectorAll('.arrowhead'), function (el) {
          _addClass(el, 'closed');
          _removeClass(el, 'opened');
        });
      }
    } else {
      _forEachNode(rows, function (row) { row.style.display = 'table-row'; });

      if (header) {
        _forEachNode(header.querySelectorAll('.arrowhead'), function (el) {
          _removeClass(el, 'closed');
          _addClass(el, 'opened');
        });
      }
    }
  }
};


/* ---------- codefold ---------- */
var codefold = {
  opened: true,

  show_plus: function (el) {
    if (el) {
      _removeClass(el, 'minus');
      _addClass(el, 'plus');
    }
  },

  show_minus: function (el) {
    if (el) {
      _addClass(el, 'minus');
      _removeClass(el, 'plus');
    }
  },

  toggle_all: function () {
    var self = this;
    var foldAll = document.getElementById('fold_all');

    if (this.opened) {
      this.show_plus(foldAll);

      _forEachNode(document.querySelectorAll('div[id^=foldopen]'), function (el) { el.style.display = 'none'; });
      _forEachNode(document.querySelectorAll('div[id^=foldclosed]'), function (el) { el.style.display = ''; });

      _forEachNode(document.querySelectorAll('div[id^=foldclosed] span.fold'), function (el) {
        self.show_plus(el);
      });

    } else {
      this.show_minus(foldAll);

      _forEachNode(document.querySelectorAll('div[id^=foldopen]'), function (el) { el.style.display = ''; });
      _forEachNode(document.querySelectorAll('div[id^=foldclosed]'), function (el) { el.style.display = 'none'; });
    }

    this.opened = !this.opened;
  },

  toggle: function (id) {
    var self = this;
    var openEl = document.getElementById('foldopen' + id);
    var closedEl = document.getElementById('foldclosed' + id);

    if (openEl) {
      openEl.style.display = (openEl.style.display === 'none') ? '' : 'none';

      var nextEl = _nextElementSibling(openEl);
      if (nextEl && nextEl.querySelectorAll) {
        _forEachNode(nextEl.querySelectorAll('span.fold'), function (el) {
          self.show_plus(el);
        });
      }
    }

    if (closedEl) {
      closedEl.style.display = (closedEl.style.display === 'none') ? '' : 'none';
    }
  },

  init: function () {
    var self = this;

    // add code folding line and global control
    _forEachNode(document.querySelectorAll('span.lineno'), function (el, index) {
      el.style.paddingRight = '4px';
      el.style.marginRight = '2px';
      el.style.display = 'inline-block';
      el.style.width = '54px';
      el.style.background = 'linear-gradient(#808080,#808080) no-repeat 46px/2px 100%';

      var span = document.createElement('span');

      if (index === 0) {
        span.className = 'fold minus';
        span.id = 'fold_all';
        span.onclick = function () { self.toggle_all(); };
      } else {
        span.className = 'fold';
      }

      el.appendChild(span);
    });

    // add toggle controls to lines with fold divs
    _forEachNode(document.querySelectorAll('div.foldopen'), function (el) {
      var id = el.getAttribute('id');
      id = id ? id.replace('foldopen', '') : '';

      var start = el.getAttribute('data-start');
      var end = el.getAttribute('data-end');

      // replace normal fold span with controls for first line
      var firstFold = el.querySelector ? el.querySelector('span.fold') : null;
      if (firstFold) {
        var spanCtl = document.createElement('span');
        spanCtl.className = 'fold minus';
        spanCtl.onclick = function () { self.toggle(id); };
        _replaceWith(firstFold, spanCtl);
      }

      // append div for folded (closed) representation
      var closedDiv = document.createElement('div');
      closedDiv.id = 'foldclosed' + id;
      closedDiv.className = 'foldclosed';
      closedDiv.style.display = 'none';
      _after(el, closedDiv);

      // extract first line from open section
      var line = (el.children && el.children[0]) ? el.children[0].cloneNode(true) : null;
      if (line) {
        _removeClass(line, 'glow');

        if (start) {
          line.innerHTML = line.innerHTML.replace(new RegExp('\\s*' + start + '\\s*$', 'g'), '');
        }

        // replace minus with plus + rebind click
        if (line.querySelectorAll) {
          _forEachNode(line.querySelectorAll('span.fold'), function (sp) {
            self.show_plus(sp);
            sp.onclick = function () { self.toggle(id); };
          });
        }

        // append ellipsis
        var ellipsisLink = document.createElement('a');
        ellipsisLink.href = "javascript:codefold.toggle('" + id + "')";
        ellipsisLink.innerHTML = '&#8230;';

        line.appendChild(document.createTextNode(' ' + (start || '')));
        line.appendChild(ellipsisLink);
        line.appendChild(document.createTextNode(end || ''));

        closedDiv.appendChild(line);
      }
    });
  }
};
/* @license-end */
