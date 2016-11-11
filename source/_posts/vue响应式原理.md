---
title: vue 响应式原理
---
<!-- Vue.js 最显著的一个功能是响应系统 —— 模型只是普通对象，修改它则更新视图。这让状态管理非常简单且直观，不过理解它的原理也很重要，可以避免一些常见问题。 -->

### 如何追踪变化

下面是一个简单的视图更新例子。

```html
<div id="app">
  <p>number: {{num}}</p>
</div>
```

```javascript
var vm = new Vue({
  el: '#app',
  data: function(){
    return {
      num: 20
    };
  },
  created: function(){
    this.num = 30;
  }
})
```

这个例子中只是把 `vm.num` 的值改变为30，没有对 DOM 进行操作，但是视图中的值却变为30了。参考官方的图示：

![模型与视图的关系图](https://cn.vuejs.org/images/data.png)

上面例子中的 `num` 对应图中右边的 `observer` 中的 b ， `observer` 函数在这里是对响应式数据进行监听的入口。

###### Observer

当我们在 `new Vue` 的时候，其实是执行了如下的过程：

```javascript
// 初始化Vue对象
function Vue(options) {
  this._init(options);
}

Vue.prototype._init = function (options) {
  // somecode...
  // initialize data observation and scope inheritance.
  this._initState();
  
  // if `el` option is passed, start compilation.
  if (options.el) {
    this.$mount(options.el);
  }
};

Vue.prototype._initState = function () {
  this._initProps();
  this._initMeta();
  this._initMethods();
  this._initData();
  this._initComputed();
};

// 调用 vm._initData 处理 data 选项
Vue.prototype._initData = function () {
  // somecode...
  // 对数据进行监听
  observe(data, this);
};

function observe(value, vm) {
  if (!value || typeof value !== 'object') {
    return;
  }
  var ob;
  // 判断 value 是否添加了 __ob__ 属性，如果已经有了证明这个数据已经被监听，会被直接返回使用。否则创建一个 Observer 对象。
  if (hasOwn(value, '__ob__') && value.__ob__ instanceof Observer) {
    ob = value.__ob__;
  } else if (shouldConvert && (isArray(value) || isPlainObject(value)) && Object.isExtensible(value) && !value._isVue) {
    ob = new Observer(value);
  }
  if (ob && vm) {
    ob.addVm(vm);
  }
  return ob;
}

// 为数据添加观察器
function Observer(value) {
  this.value = value;
  // 创建 Dep 实例
  this.dep = new Dep();
  //给 value 增加 __ob__ 属性，属性值为当前 Observer 。
  def(value, '__ob__', this);
  if (isArray(value)) {
    var augment = hasProto ? protoAugment : copyAugment;
    augment(value, arrayMethods, arrayKeys);
    //如果观察的数据为数组类型，则用 observeArray 方法观察数组。
    this.observeArray(value);
  } else {
    //用 walk 方法观察单个元素
    this.walk(value);
  }
}

// 遍历传入的对象参数的 key ，依次调用 convert 方法。
Observer.prototype.walk = function (obj) {
  var keys = Object.keys(obj);
  for (var i = 0, l = keys.length; i < l; i++) {
    this.convert(keys[i], obj[keys[i]]);
  }
};

Observer.prototype.convert = function (key, val) {
  // 调用 defineReactive 方法，this.value 为观察的 data 对象。
  defineReactive(this.value, key, val);
}; 

// 使对象的所有属性都拥有 getter 、 setter 方法。
function defineReactive(obj, key, val) {
  var dep = new Dep();

  var property = Object.getOwnPropertyDescriptor(obj, key);
  if (property && property.configurable === false) {
    return;
  }

  // cater for pre-defined getter/setters
  var getter = property && property.get;
  var setter = property && property.set;

  // 如果属性值 val 是一个对象，则继续遍历 val 的 key，并返回 val 的观察器给 childOb ，否则返回空。
  var childOb = observe(val);
  // 给对象添加 getter 、 setter 方法。
  Object.defineProperty(obj, key, {
    enumerable: true,
    configurable: true,
    get: function reactiveGetter() {
      var value = getter ? getter.call(obj) : val;
      //如果有 Dep.target ，调用 dep.depend() 
      if (Dep.target) {
        dep.depend();
        // 如果 childOb 不为空，则对 childOb 也进行依赖收集。
        if (childOb) {
          childOb.dep.depend();
        }
        if (isArray(value)) {
          for (var e, i = 0, l = value.length; i < l; i++) {
            e = value[i];
            e && e.__ob__ && e.__ob__.dep.depend();
          }
        }
      }
      return value;
    },
    set: function reactiveSetter(newVal) {
      var value = getter ? getter.call(obj) : val;
      if (newVal === value) {
        return;
      }
      if (setter) {
        setter.call(obj, newVal);
      } else {
        val = newVal;
      }
      // 对修改后的数据重新进行观察
      childOb = observe(newVal);
      // 对订阅的对象进行通知
      dep.notify();
    }
  });
}

// 通过 addDep(this) 方法把当前的 Dep 实例添加到当前正在计算的 Watcher 的依赖中。
Dep.prototype.depend = function () {
  Dep.target.addDep(this);
};

// 遍历 subs 中保存的所有 Watcher ，并调用它们的 updata 方法。
Dep.prototype.notify = function () {
  // stablize the subscriber list first
  var subs = toArray(this.subs);
  for (var i = 0, l = subs.length; i < l; i++) {
    subs[i].update();
  }
};
```

上面的 `Observer` 给响应式数据增加了一个属性 `__ob__` 作为观察器来标记响应式数据。当数据已经为响应式的情况下，会直接把观察器返回。上面没有贴出 `observeArray` 方法的代码，这个方法只是把数组数据进行遍历后再递归调用 `observer` 方法。

简单地说， `Observer` 的作用就是给 `data` 加上观察器，使其变为发布者，当 `data` 发生变化时，通知订阅了它的 `watcher` ，进而改变视图。

`defineReactive` 方法中为对象的每个属性都添加了 `getter` 和 `setter` 方法。

* 当数据的属性被访问，`getter` 方法将会被执行，如果 `Dep.target` 不为空，则会调用 `dep.depend` 和 `childObj.dep.depend` 方法进行依赖收集。`Dep.target` 是一个全局的监听器对象，里面保存了该数据的订阅对象，所以可以知道有哪些依赖可以收集。
* 当修改数据的属性时，会调用 `setter` 方法，然后通过调用 `dep.notify` 方法对订阅对象进行通知。

```javascript
function Dep() {
  this.id = uid$1++;
  this.subs = [];
}
```

> `Dep` 类是一个简单的观察者模式的实现。他的构造函数非常简单，初始化了 `id` 和 `subs` 。其中 `subs` 用来存储所有订阅它的 `Watcher` 。 `Dep.target` 表示当前正在计算的 `Watcher` ，它是全局唯一的，因为同一时间只能有一个 `Watcher` 被计算。    ———— vue.js 权威指南



###### Directive

上面 `Observer` 的代码中，Vue 在 `_initState` 执行后，也就是在给 `data` 添加 `Observer` 后，如果在初始化时指定了 `option.el` 这个选项，实例将会调用 `vm.$mount()` ：

```javascript
Vue.prototype.$mount = function (el) {
  if (this._isCompiled) {
    'development' !== 'production' && warn('$mount() should be called only once.', this);
    return;
  }
  el = query(el);
  if (!el) {
    el = document.createElement('div');
  }
  //对模板开始编译
  this._compile(el);
  this._initDOMHooks();
  if (inDoc(this.$el)) {
    this._callHook('attached');
    ready.call(this);
  } else {
    this.$once('hook:attached', ready);
  }
  return this;
};
```

可以看到 `vm.$mount()` 中会调用一次 `vm._compile()` 方法来对模板进行编译。这里以 `v-text` 为例：

```html
<div id="#app">
  <p v-text="des"></p>
  <p>{{des}}</p>
</div>
```

```javascript
new Vue({
  el: "#app",
  data: {
    des: "directive source"
  }
})
```

当 `Vue` 编译模板到 v-text 指令时，会对该指令进行解析。会为该 DOM 元素注册指令，并将其绑定到 vm 上。绑定指令时会根据指令的信息为 v-text 指令注册一个订阅器


```javascript
Vue.prototype._compile = function (el) {
  var options = this.$options;

  // transclude and init element
  // transclude can potentially replace original
  // so we need to keep reference; this step also injects
  // the template and caches the original attributes
  // on the container node and replacer node.
  var original = el;
  // 将 template 编译成一段 document fragment ,返回一个 el 对象。
  el = transclude(el, options);
  // 把 el 对象保存到 vm.$el
  this._initElement(el);

  // handle v-pre on root node (#2026)
  if (el.nodeType === 1 && getAttr(el, 'v-pre') !== null) {
    return;
  }

  // root is always compiled per-instance, because
  // container attrs and props can be different every time.
  var contextOptions = this._context && this._context.$options;
  var rootLinker = compileRoot(el, options, contextOptions);

  // resolve slot distribution
  resolveSlots(this, options._content);

  // compile and link the rest
  var contentLinkFn;
  var ctor = this.constructor;
  // component compilation can be cached
  // as long as it's not using inline-template
  if (options._linkerCachable) {
    contentLinkFn = ctor.linker;
    if (!contentLinkFn) {
      contentLinkFn = ctor.linker = compile(el, options);
    }
  }

  // link phase
  // make sure to link root with prop scope!
  var rootUnlinkFn = rootLinker(this, el, this._scope);
  // 调用 compile(el, options) 解析指令
  var contentUnlinkFn = contentLinkFn ? contentLinkFn(this, el) : compile(el, options)(this, el);

  // register composite unlink function
  // to be called during instance destruction
  this._unlinkFn = function () {
    rootUnlinkFn();
    // passing destroying: true to avoid searching and
    // splicing the directives
    contentUnlinkFn(true);
  };

  // finally replace original
  if (options.replace) {
    replace(original, el);
  }

  this._isCompiled = true;
  this._callHook('compiled');
};
```

从上面的代码可以看出， `vm._compile` 方法编译是从调用 `transclude` 方法开始的，这里如果使用了模板引擎，比如 `<template lang="jade">` ，将会在里面调用了一个 `transcludeTemplate` 的方法，最后的结果都是返回一个 `document fragment` 给 `el` 。之后会调用 `compile` 方法对指令进行解析。

```javascript
function compile(el, options, partial) {
  // link function for the node itself.
  // 调用 compileNode 方法，对节点进行解析。
  var nodeLinkFn = partial || !options._asComponent ? compileNode(el, options) : null;
  // link function for the childNodes
  // 调用 compileNodeList 方法遍历子节点，并对子节点进行解析。
  var childLinkFn = !(nodeLinkFn && nodeLinkFn.terminal) && !isScript(el) && el.hasChildNodes() ? compileNodeList(el.childNodes, options) : null;

  /**
     * A composite linker function to be called on a already
     * compiled piece of DOM, which instantiates all directive
     * instances.
     *
     * @param {Vue} vm
     * @param {Element|DocumentFragment} el
     * @param {Vue} [host] - host vm of transcluded content
     * @param {Object} [scope] - v-for scope
     * @param {Fragment} [frag] - link context fragment
     * @return {Function|undefined}
     */

  // 创建指令对象
  return function compositeLinkFn(vm, el, host, scope, frag) {
    // cache childNodes before linking parent, fix #657
    var childNodes = toArray(el.childNodes);
    // link
    var dirs = linkAndCapture(function compositeLinkCapturer() {
      if (nodeLinkFn) nodeLinkFn(vm, el, host, scope, frag);
      if (childLinkFn) childLinkFn(vm, childNodes, host, scope, frag);
    }, vm);
    return makeUnlinkFn(vm, dirs);
  };
}

function compileNode(node, options) {
  var type = node.nodeType;
  // 如果为元素节点，调用 compileElement 方法解析，如果为文字节点，调用 compileTextNode 方法解析。
  if (type === 1 && !isScript(node)) {
    return compileElement(node, options);
  } else if (type === 3 && node.data.trim()) {
    return compileTextNode(node, options);
  } else {
    return null;
  }
}
```

`compile` 方法中是通过 `compileNode` 方法来解析节点的，如果节点拥有子节点，则调用 `compileNodeList` 方法先遍历其所有子节点，然后再递归调用 `compileNode` 方法来解析子节点。

> 由于 DOM 元素本身就是树结构，这种递归方法也就是常见的树的深度遍历方法，这样就可以完成整个 DOM 树节点的解析。     ———— vue.js 权威指南

调用 `compileNode(el, option)` 方法解析时，会根据节点的 `nodeType` 来调用不同的 方法来解析。

* `type === 1 && !isScript(node)` ： `nodeType` 为1，是一个元素节点且不是 script 标签。则调用 `compileElement` 方法来解析。
* `type === 3 && node.data.trim()`: `nodeType` 为3，是 Element 或者 Attr 中实际的文字。则调用 `compileTextNode` 方法来解析， `node.data.trim()` 会将文字两头的空格去掉。

所以例子中的 div,p 是用 `compileElement` 方法解析的。 `{{des}}` 是用 `compileTextNode` 方法解析的。

每当执行完 `compileElement` 方法后会返回一个 `linkFn` ，这是一个去实例化指令，将指令和元素 link 起来，并将元素替换到 DOM 树中。

解析完成后，会返回一个 `compositeLinkFn` 方法，这个方法执行了 `linkAndCapture` 方法，通过调用 `compile` 过程中生成的 `link` 方法创建指令对象，再对指令方法做一些绑定操作。代码如下：

```javascript
function compile(el, options, partial) {
  // somecode...
  // 创建指令对象
  return function compositeLinkFn(vm, el, host, scope, frag) {
    // cache childNodes before linking parent, fix #657
    var childNodes = toArray(el.childNodes);
    // link
    var dirs = linkAndCapture(function compositeLinkCapturer() {
      if (nodeLinkFn) nodeLinkFn(vm, el, host, scope, frag);
      if (childLinkFn) childLinkFn(vm, childNodes, host, scope, frag);
    }, vm);
    return makeUnlinkFn(vm, dirs);
  };
}

function linkAndCapture(linker, vm) {
  /* istanbul ignore if */
  if ('development' === 'production') {}
  var originalDirCount = vm._directives.length;
  // 执行前面传入的 linker 方法
  linker();
  var dirs = vm._directives.slice(originalDirCount);
  // 对 _directives 数组进行排序
  dirs.sort(directiveComparator);
  // 遍历 _directives 数组
  for (var i = 0, l = dirs.length; i < l; i++) {
    // 对每个 _directive 调用 _bind 方法
    dirs[i]._bind();
  }
  return dirs;
}

// 把收集的指令传给 nodeLinkFn
function makeNodeLinkFn(directives) {
  return function nodeLinkFn(vm, el, host, scope, frag) {
    // reverse apply because it's sorted low to high
    var i = directives.length;
    // 对 directives 中的每个 directive 调用 _bindDir 方法
    while (i--) {
      vm._bindDir(directives[i], el, host, scope, frag);
    }
  };
}

function makeChildLinkFn(linkFns) {
  return function childLinkFn(vm, nodes, host, scope, frag) {
    var node, nodeLinkFn, childrenLinkFn;
    //遍历 linkFns 
    for (var i = 0, n = 0, l = linkFns.length; i < l; n++) {
      node = nodes[n];
      nodeLinkFn = linkFns[i++];
      // 把 linkFn 赋值给 childrenLinkFn 
      childrenLinkFn = linkFns[i++];
      // cache childNodes before linking parent, fix #657
      var childNodes = toArray(node.childNodes);
      if (nodeLinkFn) {
        nodeLinkFn(vm, node, host, scope, frag);
      }
      if (childrenLinkFn) {
        // 执行所有 linkFn
        childrenLinkFn(vm, childNodes, host, scope, frag);
      }
    }
  };
}

Vue.prototype._bindDir = function (descriptor, node, host, scope, frag) {
  // 实例化 Directive 对象，并将其添加到 _directives 数组中
  this._directives.push(new Directive(descriptor, this, node, host, scope, frag));
};
```

首先调用了传入的 `linker` 方法，遍历了 compile 过程中生成的所有 linkFn 并调用。这里的 linkFn 可以是由 `compileElement`，`compileTextNode`，`compileNodeList` 这三个方法生成的，遍历 linkFn 的方式也是深度遍历，如果有子节点会调用 `childLinkFn` 方法进行递归，没有的话就调用 `nodeLinkFn` 方法，然后用 `vm._bindDir` 的方法把元素和指令绑定起来。

`Vue.prototype._bindDir` 方法是将实例化的 `Directive` 对象添加到 `vm._directives` 数组中的。接下来对创建好的 `directives` 进行排序，然后遍历 `directives` 调用 `_bind` 方法对每个 `directive` 对指令进行初始化操作。

```javascript
Directive.prototype._bind = function () {
  var name = this.name;
  // 复制描述指令的对象
  var descriptor = this.descriptor;

  // remove attribute
  if ((name !== 'cloak' || this.vm._isCompiled) && this.el && this.el.removeAttribute) {
    var attr = descriptor.attr || 'v-' + name;
    this.el.removeAttribute(attr);
  }

  // copy def properties
  // 复制存放指令相关操作的对象
  var def = descriptor.def;
  if (typeof def === 'function') {
    this.update = def;
  } else {
    // 对实例扩展该指令相关操作方法
    extend(this, def);
  }

  // setup directive params
  this._setupParams();

  // initial bind
  // 如果该指令有 bind 方法则执行
  if (this.bind) {
    this.bind();
  }
  this._bound = true;

  if (this.literal) {
    this.update && this.update(descriptor.raw);
  } else if ((this.expression || this.modifiers) && (this.update || this.twoWay) && !this._checkStatement()) {
    // wrapped updater for context
    var dir = this;
    if (this.update) {
      this._update = function (val, oldVal) {
        if (!dir._locked) {
          dir.update(val, oldVal);
        }
      };
    } else {
      this._update = noop$1;
    }
    var preProcess = this._preProcess ? bind(this._preProcess, this) : null;
    var postProcess = this._postProcess ? bind(this._postProcess, this) : null;
    // 创建 watcher ，把 _update 作为回调函数。
    var watcher = this._watcher = new Watcher(this.vm, this.expression, this._update, // callback
    {
      filters: this.filters,
      twoWay: this.twoWay,
      deep: this.deep,
      preProcess: preProcess,
      postProcess: postProcess,
      scope: this._scope
    });
    // v-model with inital inline value need to sync back to
    // model instead of update to DOM on init. They would
    // set the afterBind hook to indicate that.
    if (this.afterBind) {
      this.afterBind();
    } else if (this.update) {
      this.update(watcher.value);
    }
  }
};
```

在上面 `_bind` 方法的源码中，`this.descriptor` 是一个对象，它包含了指令的相关描述。例如 `this.descriptor.def` 里是存放指令相关操作的对象，`this.descriptor.expression` 里存放的是绑定的数据。

当我们使用 `v-text` 指令时：

```html
<p v-text="page"></p>
```

Vue.js 会根据一个保存了所有指令的对象，去找对应指令的相关操作。

```javascript
// must export plain object
var directives = {
  text: text$1,
  html: html,
  'for': vFor,
  'if': vIf,
  show: show,
  model: model,
  on: on$1,
  bind: bind$1,
  el: el,
  ref: ref,
  cloak: cloak
};

var text$1 = {

  bind: function bind() {
    this.attr = this.el.nodeType === 3 ? 'data' : 'textContent';
  },

  update: function update(value) {
    this.el[this.attr] = _toString(value);
  }
};
```

最后生成的 `this.descriptor` 对象如下：

![WechatIMG1.jpg](https://img.alicdn.com/tps/TB1czRoOXXXXXarXFXXXXXXXXXX-320-249.png)

回到 `_bind` 方法中，接下来还定义了一个 `_update` 方法，并创建了 Watcher，把 `_update` 方法作为它的回调函数，将 Directive 和 Watcher 进行关联，一旦 Watcher 观察到指令表达式的值发生变化时，会调用 Directive 的 `_update` 方法，最终调用 `v-text` 的 `update` 方法更新 DOM 节点。

接下来看看 Watcher 吧！



###### Watcher

```javascript
var watcher = this._watcher = new Watcher(this.vm, this.expression, this._update, // callback
{
  filters: this.filters,
  twoWay: this.twoWay,
  deep: this.deep,
  preProcess: preProcess,
  postProcess: postProcess,
  scope: this._scope
});
```

由上面 Directive 中创建 Watcher 的时候可以看到传入了指令对象、指令的表达式、`_update` 方法以及一个对象。接下来看 Watcher 的源码：

```javascript
function Watcher(vm, expOrFn, cb, options) {
  // mix in options
  // 混合属性
  if (options) {
    extend(this, options);
  }
  // 判断 vm.expression 是不是一个方法
  var isFn = typeof expOrFn === 'function';
  this.vm = vm;
  vm._watchers.push(this);
  this.expression = expOrFn;
  this.cb = cb;
  this.id = ++uid$2; // uid for batching
  this.active = true;
  this.dirty = this.lazy; // for lazy watchers
  this.deps = [];
  this.newDeps = [];
  this.depIds = new _Set();
  this.newDepIds = new _Set();
  this.prevError = null; // for async error stacks
  // parse expression for getter/setter
  if (isFn) {
    this.getter = expOrFn;
    this.setter = undefined;
  } else {
    // 对 expression 进行解析，将其转换成一个对象
    var res = parseExpression(expOrFn, this.twoWay);
    this.getter = res.get;
    this.setter = res.set;
  }
  // 对当前的 Watcher 进行求值，收集依赖关系，如果有 lazy 属性，则不会进行求值，用在 _initComputed 的时候。
  this.value = this.lazy ? undefined : this.get();
  // state for avoiding false triggers for deep and Array
  // watchers during vm._digest()
  this.queued = this.shallow = false;
}
```

Watcher 构造函数里面如果传入的 expOrFn 是一个的方法，则把这个方法赋给 Watcher 的 getter。否则会调用 parseExpression 方法解析传入的 expression，并将其进行转换，返回一个对象，如下图：

![WechatIMG1.jpg](https://img.alicdn.com/tps/TB1Lrg7NVXXXXXaapXXXXXXXXXX-320-143.png)

最后 `this.get` 方法会对当前的 Watcher 进行求值，收集依赖关系，如果有 `lazy` 属性，Watcher 则不会进行求值，用在 `_initComputed` 的时候。

```javascript
Watcher.prototype.get = function () {
  this.beforeGet();
  // 将当前实例赋给 scope
  var scope = this.scope || this.vm;
  var value;
  try {
    // 获取需要观察的数据，相当于获取 vm.num
    value = this.getter.call(scope, scope);
  } catch (e) {
    // 抛出异常
    if ('development' !== 'production' && config.warnExpressionErrors) {
      warn('Error when evaluating expression ' + '"' + this.expression + '": ' + e.toString(), this.vm);
    }
  }
  // "touch" every property so they are all tracked as
  // dependencies for deep watching
  if (this.deep) {
    traverse(value);
  }
  if (this.preProcess) {
    value = this.preProcess(value);
  }
  if (this.filters) {
    value = scope._applyFilters(value, null, this.filters, false);
  }
  if (this.postProcess) {
    value = this.postProcess(value);
  }
  this.afterGet();
  return value;
};

// 将 Dep.target 设置为当前的 Watcher
Watcher.prototype.beforeGet = function () {
  Dep.target = this;
};

Dep.prototype.depend = function () {
  Dep.target.addDep(this);
};

// 将 dep 添加到当前 Wathcer 实例的依赖中
Watcher.prototype.addDep = function (dep) {
  var id = dep.id;
  if (!this.newDepIds.has(id)) {
    this.newDepIds.add(id);
    this.newDeps.push(dep);
    if (!this.depIds.has(id)) {
      dep.addSub(this);
    }
  }
};

// 将当前的 Watcher 实例添加到订阅列表中
Dep.prototype.addSub = function (sub) {
  this.subs.push(sub);
};

// 将 Dep.target 设为 null
Watcher.prototype.afterGet = function () {
  Dep.target = null;
  var i = this.deps.length;
  while (i--) {
    var dep = this.deps[i];
    if (!this.newDepIds.has(dep.id)) {
      dep.removeSub(this);
    }
  }
  var tmp = this.depIds;
  this.depIds = this.newDepIds;
  this.newDepIds = tmp;
  this.newDepIds.clear();
  tmp = this.deps;
  this.deps = this.newDeps;
  this.newDeps = tmp;
  this.newDeps.length = 0;
};
```

`Watcher.prototype.get` 调用了 `this.getter.call(scope, scope)` 方法，相当于 `vm.num` ，这么做会触发对象的 `getter` ，也就会执行 `get` 方法，在上面的 Observer 部分中可以看到 `defineReactive` 那里 `get` 方法会触发依赖收集。在此之前 `beforeGet` 方法已经把 `Dep.target` 设置为当前的 Watcher ， Observer 中的 `Dep.target.addDep(this)` 也就是调用 `Watcher.prototype.addDep` 方法，会将 Dep 实例添加到 Watcher 实例的依赖中，然后再通过 `addSub` 方法把当前的 Watcher 实例添加到 dep 的订阅列表中。

最后用一张图来总结一下Vue响应式原理的整个过程。

![WechatIMG1.jpg](https://img.alicdn.com/tps/TB18nVIOXXXXXa_XpXXXXXXXXXX-2112-1548.jpg)

