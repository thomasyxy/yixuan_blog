---
title: vue2.0 响应式原理
---
### 

![data.png](https://img.alicdn.com/tps/TB1kAuOOXXXXXbDapXXXXXXXXXX-1200-750.png)

Mustache 标签会被相应数据对象的 msg 属性的值替换。每当这个属性变化时它也会更新。

```html
<div>文本插值是最基本的形式使用双大括号:{{num}}</div>
```

有时候只需要渲染一次数据，后续数据的变化不再关心，可以只处理单次插值，今后的数据变化就不会再引起插值更新了。

```html
<div>在变量前加*只处理一次，之后不会再更新: {{*num}}</div>
```

双 Mustache 标签将数据解析为纯文本而不是 HTML。为了输出真的 HTML 字符串，需要用三 Mustache 标签：

```html
<div>此处插入了一段html代码: {{{ raw_html }}}</div>
```

Mustache 标签也可以用在 HTML 特性 (Attributes) 内：

```html
<div id="item-{{ id }}"></div>
```

### 表达式

Vue.js 在数据绑定内支持全功能的 JavaScript 表达式,允许在表达式后添加可选的“过滤器 (Filter) ”，类似于Linux中的管道，以“管道符”指示：

```html
<div>{{*(num+1)}}</div>
<div>{{false ? 'YES' : 'NO'}}</div>
<div>{{message.split(',')}}</div>
<div>{{ message.split('').reverse().join('') | uppercase}}</div>
```

### 分隔符

vue.js中数据绑定语法被设计为可配置的。如果不习惯Mustache风格的语法可以自定义。

源码如下：

``` javascript
var delimiters = ['{{', '}}'];
var unsafeDelimiters = ['{{{', '}}}'];

var config = Object.defineProperties({
  ......
},{
    delimiters: { /**
                   * Interpolation delimiters. Changing these would trigger
                   * the text parser to re-compile the regular expressions.
                   *
                   * @type {Array<String>}
                   */

      get: function get() {
        return delimiters;
      },
      set: function set(val) {
        delimiters = val;
        compileRegex();
      },
      configurable: true,
      enumerable: true
    },
    unsafeDelimiters: {
      get: function get() {
        return unsafeDelimiters;
      },
      set: function set(val) {
        unsafeDelimiters = val;
        compileRegex();
      },
      configurable: true,
      enumerable: true
    }
  });
```

自定义分隔符：


```javascript
//文本插值的语法由{{ message }}改为{% message %}
Vue.config.delimiters = ["{%", "%}"];

//HTML插值的语法由{{{ html }}}改为{{% html %}}
Vue.config.unsafeDelimiters = ["{{%", "%}}"];
```

> 注意，在2.0版本中：
> ~~`Vue.config.delimiters`~~ 由全局配置被改动为一个组件级别的配置。
> ~~`Vue.config.unsafeDelimiters`~~ 也被废弃，用`v-html`代替。
