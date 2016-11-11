---
title: vue2.0 生命周期
---
<!-- 在创建Vue实例后，将会先后经历 创建 —— 编译 —— 销毁 这三个阶段-->

### 钩子函数

先挂上Vue官网的图：

![Vue生命周期图](https://img.alicdn.com/tps/TB1advgOXXXXXXPapXXXXXXXXXX-1200-2800.png)

vue2.0 对钩子做出了较大的变动，如下图：

![Vue LifeCycle hooks](https://img.alicdn.com/tps/TB1AKLaOXXXXXbBapXXXXXXXXXX-847-572.png)

可以从一个例子中大概了解钩子的用法：

```javascript
var vm = new Vue({
  el: '#app',
  beforeCreate: function () {
    console.log('beforeCreate')
  },
  created: function () {
    console.log('created')
  },
  mounted: function () {
    console.log('mounted')
  }
})

// 结果： beforeCreate，created，mounted
```

接下来看看钩子的实现原理 ，首先还是从 Vue 实例的创建开始：

```javascript
// 这里是编译完的代码：
(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global.Vue = factory());
}(this, (function () { 'use strict';
// 略。。。
return Vue$3;
})));
```

在这个方法中传入了两个参数： `global` 和 `factory`，`global`的值是`this`，其实也就是全局对象`Window`，`factory`是一个返回了 Vue 对象的方法。最后也就是执行 `Window.Vue = function(){ return Vue$3 }`

而我们在创建一个 Vue 实例时执行的 `var vm = new Vue({...})`，实际就是实例化了 `factory` 方法中返回的 `Vue$3` 对象。

###### `beforeCreate` 和 `created`

* `beforeCreate` ：组件实例刚刚被创建，组件属性计算之前，如 `data` 属性等。
* `created` ：组件实例创建完成，属性已绑定，但 DOM 还卫生成， `$el` 还不存在。

```javascript
function Vue$3 (options) {
  if ("development" !== 'production' &&
    !(this instanceof Vue$3)) {
    warn('Vue is a constructor and should be called with the `new` keyword')
  }
  // 执行 _init 方法初始化 Vue 对象，添加属性和方法。
  this._init(options)
}

initMixin(Vue$3)

function initMixin (Vue) {
  // 用于初始化Vue对象的 _init 方法
  Vue.prototype._init = function (options) {
    var vm = this
    // a uid
    vm._uid = uid++
    // a flag to avoid this being observed
    vm._isVue = true
    // merge options
    if (options && options._isComponent) {
      // optimize internal component instantiation
      // since dynamic options merging is pretty slow, and none of the
      // internal component options needs special treatment.
      initInternalComponent(vm, options)
    } else {
      vm.$options = mergeOptions(
        resolveConstructorOptions(vm),
        options || {},
        vm
      )
    }
    /* istanbul ignore else */
    {
      initProxy(vm)
    }
    // expose real self
    vm._self = vm
    initLifecycle(vm)
    initEvents(vm)
    // 执行 beforeCreate
    callHook(vm, 'beforeCreate')
    initState(vm)
    // 执行 created
    callHook(vm, 'created')
    initRender(vm)
  }
  // 略。。。
}

function callHook (vm, hook) {
  var handlers = vm.$options[hook]
  if (handlers) {
    // 执行钩子函数
    for (var i = 0, j = handlers.length; i < j; i++) {
      handlers[i].call(vm)
    }
  }
  // 发布事件，某些钩子可能会触发事件
  vm.$emit('hook:' + hook)
}
```

上面的源码中可以看到，`beforeCreate` 和 `created` 的区别仅仅是 `beforeCreate`  在 `initState` 方法之前执行， `created` 在 `initState` 之后执行。 `initState` 
方法的作用大致上是初始化组件的属性和数据观察。

所有钩子函数都是通过一个 `callHook` 的方法来执行的。

###### `beforeMount` 和 `mounted`

* `beforeMount` ：模板编译/挂载之前
* `mounted` ：模板编译/挂载之后

```javascript
Vue.prototype._mount = function (
el,
 hydrating
) {
  var vm = this
  // 创建 vm.$el
  vm.$el = el
  if (!vm.$options.render) {
    vm.$options.render = emptyVNode
    {
      /* istanbul ignore if */
      if (vm.$options.template) {
        warn(
          'You are using the runtime-only build of Vue where the template ' +
          'option is not available. Either pre-compile the templates into ' +
          'render functions, or use the compiler-included build.',
          vm
        )
      } else {
        warn(
          'Failed to mount component: template or render function not defined.',
          vm
        )
      }
    }
  }
  // 执行 beforeMount
  callHook(vm, 'beforeMount')
  // 创建观察者
  vm._watcher = new Watcher(vm, function () {
    // 执行 update 方法，下面会介绍
    vm._update(vm._render(), hydrating)
  }, noop)
  hydrating = false
  // root instance, call mounted on self
  // mounted is called for child components in its inserted hook
  if (vm.$root === vm) {
    vm._isMounted = true
    // 执行 mounted
    callHook(vm, 'mounted')
  }
  return vm
}
```

这里源码和图有些出入，可以看到在 `beforeMount` 之前， `vm.$el` 已经被创建了，后面是调用 `patch` 方法处理虚拟 DOM 后并将结果更新给 `vm.$el` 。在 `beforeMount` 之后会创建一个观察者并执行传入的 `update` 方法，然后判断 `vm.$root` ，因为在 `initLifecycle` 中 `vm.$root` 被赋值，所以会执行 `mounted` 方法。

###### `beforeUpdate` 和 `updated`

* `beforeUpdate` ：组件更新之前
* `updated` ：组件更新之后

```javascript
Vue.prototype._update = function (vnode, hydrating) {
  var vm = this
  // 判断模板是否已经被编译
  if (vm._isMounted) {
    // 执行 beforeUpdate
    callHook(vm, 'beforeUpdate')
  }
  var prevEl = vm.$el
  var prevActiveInstance = activeInstance
  activeInstance = vm
  // 将旧的 vm._vnode 赋给 prevVnode
  var prevVnode = vm._vnode
  // vnode 是 _render 方法执行后返回的新的 VNode 对象，类似于一个 Dom
  vm._vnode = vnode
  // 判断是否是第一次渲染
  if (!prevVnode) {
    // Vue.prototype.__patch__ is injected in entry points
    // based on the rendering backend used.
    vm.$el = vm.__patch__(vm.$el, vnode, hydrating)
  } else {
    vm.$el = vm.__patch__(prevVnode, vnode)
  }
  activeInstance = prevActiveInstance
  // update __vue__ reference
  if (prevEl) {
    prevEl.__vue__ = null
  }
  if (vm.$el) {
    vm.$el.__vue__ = vm
  }
  // if parent is an HOC, update its $el as well
  if (vm.$vnode && vm.$parent && vm.$vnode === vm.$parent._vnode) {
    vm.$parent.$el = vm.$el
  }
  if (vm._isMounted) {
    // 执行 updated
    callHook(vm, 'updated')
  }
}
```

从上一部分的 `beforeMount` 之后执行了 `_update` 方法，但是第一次执行时 `vm._isMounted` 在 `initLifecycle` 方法执行时被赋值为 false ，所以并不执行 `beforeUpdate` 和 `updated` ，然后在执行 `mounted` 之前，将 `vm._isMounted` 改为 true 。当数据更新时，Watcher 观察后会再次执行 `_update` 方法，此时执行 `beforeUpdate` 和 `updated` 的条件已经满足，先执行了 `beforeUpdate`，然后会执行 `patch` 来检查虚拟 DOM 并更新 `vm.$el`，再执行 `updated` 。

###### `beforeDestroy` 和 `destroyed`

* `beforeDestroy`：组件销毁前调用
* `beforeDestroy`：组件销毁后调用


###### `activated` 和 `deactivated`

* `activated`：for `keep-alive`，组件被激活时调用
* `deactivated`：for `keep-alive`，组件被移除时调用