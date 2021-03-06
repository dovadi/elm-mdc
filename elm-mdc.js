// BEGIN: IE >=9 CustomEvent polyfill
// from:
// https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
(function () {

  if ( typeof window.CustomEvent === "function" ) return false;

  function CustomEvent ( event, params ) {
    params = params || { bubbles: false, cancelable: false, detail: undefined };
    var evt = document.createEvent("CustomEvent");
    evt.initCustomEvent( event, params.bubbles, params.cancelable, params.detail );
    return evt;
   }

  CustomEvent.prototype = window.Event.prototype;

  window.CustomEvent = CustomEvent;
})();
// END: IE >=9 CustomEvent polyfill


var traverse = function(node, f) {
    var firstNode = node;
    var limit = 1000;
    while (node) {
        f(node);
        if (!limit--) {
            break;
        }
        if (node.firstChild) {
            node = node.firstChild;
            continue;
        }
        if (node.nextSibling) {
            node = node.nextSibling;
            continue;
        }
        node = node.parentElement;
        while (node) {
            if (node === firstNode) {
                node = null;
                break;
            }
            if (node && node.nextSibling) {
                node = node.nextSibling;
                break;
            }
            if (node.parentElement) {
                node = node.parentElement;
                continue;
            }
            node = null;
        }
        if (!node) {
            break;
        }
    };
};


var dispatchElmMdcInit = function(node) {
    if (!node) {
        console.log("WARN: should not happen!");
        return;
    }
    if (!node.classList) {
        return;
    }
    for  (var i = 0; i < node.classList.length; i++) {
        var cs = node.classList[i];
        if (cs === "mdc-slider") {
            node.dispatchEvent(new CustomEvent("ElmMdcInit"));
            break;
        }
    }
};


var observer = new MutationObserver(function(mutations) {
    for (var i = 0; i < mutations.length; i++) {
      if (mutations[i].type !== "childList") {
          continue;
      }
      var mutation = mutations[i];
      var nodes = mutation.addedNodes;
      for (var j = 0; j < nodes.length; j++) {
          traverse(nodes[j], dispatchElmMdcInit);
      }
    }
});


observer.observe(document.body, {
    childList: true,
    subtree: true
});


var dispatchWindowResize = function(node) {
    if (!node) {
        console.log("WARN: should not happen!");
        return;
    }
    if (!node.classList) {
        return;
    }
    for  (var i = 0; i < node.classList.length; i++) {
        var cs = node.classList[i];
    }
    node.dispatchEvent(new CustomEvent("elm-mdc-resize"));
};


window.addEventListener("resize", function() {
    traverse(document.body, dispatchWindowResize);
});

var dispatchReconfigure = function(node) {
    node.dispatchEvent(new CustomEvent("ElmMdcReconfigure"));
};

var observer1 = new MutationObserver(function(mutations) {
    for (var i = 0; i < mutations.length; i++) {
        var target = mutations[i].target;
        if (!target) {
            break;
        }
        if (!target.classList) {
            break;
        }
        if (target.classList.contains("elm-mdc--reconfigure")) {
            dispatchReconfigure(target);
        }
    }
});


observer1.observe(document.body, {
    subtree: true,
    attributes: true,
    attributeFilter: [ "class" ]
});


var dispatchMouseMove = function(evtName, node, pageX) {
    if (!node) {
        console.log("WARN: should not happen!");
        return;
    }
    if (!node.classList) {
        return;
    }
    for (var i = 0; i < node.classList.length; i++) {
        var cs = node.classList[i];
        if (cs === "mdc-slider") {
            var event = new CustomEvent(evtName);
            event.pageX = pageX;
            node.dispatchEvent(event);
            break;
        }
    }
};


document.body.addEventListener("mousemove", function(event) {
    traverse(document.body, function(node) {
        dispatchMouseMove("ElmMdcMouseMove", node, event.pageX);
    });
});


document.body.addEventListener("touchmove", function(event) {
    traverse(document.body, function(node) {
        dispatchMouseMove("ElmMdcTouchMove", node, event.pageX);
    });
});


document.body.addEventListener("pointermove", function(event) {
    traverse(document.body, function(node) {
        dispatchMouseMove("ElmMdcPointerMove", node, event.pageX);
    });
});


var dispatchMouseUp = function(evtName, node, pageX) {
    if (!node) {
        console.log("WARN: should not happen!");
        return;
    }
    if (!node.classList) {
        return;
    }
    for (var i = 0; i < node.classList.length; i++) {
        var cs = node.classList[i];
        if (cs === "mdc-slider") {
            var event = new CustomEvent(evtName);
            event.pageX = pageX;
            node.dispatchEvent(event);
            break;
        }
    }
};


document.body.addEventListener("mouseup", function(event) {
    traverse(document.body, function(node) {
        dispatchMouseUp("ElmMdcMouseUp", node, event.pageX);
    });
});

document.body.addEventListener("touchend", function(event) {
    traverse(document.body, function(node) {
        dispatchMouseUp("ElmMdcTouchEnd", node, event.pageX);
    });
});

document.body.addEventListener("pointerup", function(event) {
    traverse(document.body, function(node) {
        dispatchMouseUp("ElmMdcPointerUp", node, event.pageX);
    });
});
