---
title: vue 指令
---
<!--指令 (Directives) 是特殊的带有前缀 v- 的特性。指令的值限定为绑定表达式，因此上面提到的 JavaScript 表达式及过滤器规则在这里也适用。指令的职责就是当其表达式的值改变时把某些特殊的行为应用到 DOM 上。-->

### 内部指令

###### v-if,v-show,v-else

这3个指令的用法比较相似，都属于条件渲染，根据表达式中的值来显示或隐藏dom元素，和angular中的用法是一样的。
例：

```css
      .container{
        width: 300px;
        height: 300px;
        margin: 0;
        padding: 0;
      }
      .inner-block{
        width: 100px;
        height: 100px;
        float: left;
        background: blue;
        margin: 0;
        padding: 0;
        list-style-type: none;
        text-align: center;
        color: #fff;
        line-height: 100px;
        font-size: 20px;
      }
```

```html
    <div id="app">
      <div class="container">
        <div class="inner-block" v-if="step==1">1</div>
        <div class="inner-block" v-if="step==2">2</div>
        <div class="inner-block" v-if="step==3">3</div>
        <div class="inner-block" v-if="step==4">4</div>
        <div class="inner-block" v-if="step==5">5</div>
        <div class="inner-block" v-if="step==6">6</div>
        <div class="inner-block" v-if="step==7">7</div>
        <div class="inner-block" v-if="step==8">8</div>
      </div>
      <ul class="container">
        <li class="inner-block" v-show="step==1">1</li>
        <li class="inner-block" v-show="step==2">2</li>
        <li class="inner-block" v-show="step==3">3</li>
        <li class="inner-block" v-show="step==4">4</li>
        <li class="inner-block" v-show="step==5">5</li>
        <li class="inner-block" v-show="step==6">6</li>
        <li class="inner-block" v-show="step==7">7</li>
        <li class="inner-block" v-show="step==8">8</li>
        <li class="inner-block" v-show="step==9">9</li>
      </ul>
      <button @click="runStep">开始计数</button>
```

```javascript
      var vm = new Vue({
        el: '#app',
        data: {
          step: 1,
          block: 1
        },
        methods:{
          runStep: function(){
            setInterval(function(){
              if(vm.step < 8){
                vm.step++;
              }else{
                vm.step = 1;
              }
            },1000);
          }
        }
      })
```

>区别：`v-if`只有当第一次条件为ture时，才会编译并保存。`v-show`则元素始终存在，表达式为true时才显示。因此若需要惰性渲染dom元素时，用`v-if`来控制会比较好，若可能切换的次数较多时，可以用`v-show`来控制。


###### v-model

`v-model` 指令在表单控件元素上创建双向数据绑定。根据控件类型它自动选取正确的方法更新元素。

```html
      <div id="app">
        <input type="text"  v-model="name">
        <span>{{name}}</span>
      </div>
```


```javascript
      var vm = new Vue({
        el: '#app',
        data: {
          name: 'yixuan'
        }
      })
```

v-model可以后面添加一些参数来对用户的输入进行处理。

* `number`:将用户的输入自动转换为Number类型。
* `lazy`:将数据改到在change事件中发生。
* `debounce`:设置一个最小延时，在每次敲击后延时同步输入的数据。注意，此参数并不会延迟执行input事件，只是延迟改变目标数据。


```html
      <input v-model="age" number/>
      <input v-model="name" lazy/>
      <input v-model="delay" debounce="500"/>
```

>但是在vue2.0中，这些参数都被取消了，`number`，`lazy`被改为修饰符来使用，`debounce`直接被废弃。

```html
      <input v-model.number="age" />
      <input v-model.lazy="name" />
```

###### ~~v-repeat(已废弃)~~，v-for

`v-repeat`在1.0之前已废弃，`v-for`需要特殊的别名（1.0.17版本后支持 of 分隔符），如:

```html
	<li v-for="item in/of mainList"></li>
```

```css
  .nav{
    width: 1000px;
    height: 30px;
    margin: 0;
    padding: 0;
    margin: 0 auto;
  }
  .nav-list{
    width: 100%;
    margin: 0;
    padding: 0;
  }
  .item{
    position: relative;
    float: left;
    width: 100px;
    height: 30px;
    list-style-type: none;
    text-align: center;
    line-height: 30px;
    cursor: pointer;
  }
  .nav-list:after{
    content: "";
    display: table;
    clear: both;
  }
  .item:hover{
    color: #999;
  }
  .sub-list{
    position: absolute;
    left: 0;
    top: 40px;
    width: 100px;
    margin: 0;
    padding: 0;
  }
  .sub-item{
    float: left;
    width: 100px;
    height: 30px;
    margin: 5px;
    list-style-type: none;
    color: #000;
  }
  .sub-item:hover{
    color: #999;
  }
```

```html
    <div id="app" class="nav">
      <ul class="nav-list">
        <template v-for="item in mainList">
          <li class="item" data-idx="{{ $index }}" @click="showSubList">
            {{ item.title }}
            <ul class="sub-list" v-if="item.subList" v-show="item.isShow">
              <li v-for="(key, subItem) in item.subList" class="sub-item sub-item{{ $index }}">
                {{ subItem }}
              </li>
            </ul>
          </li>
        </template>
      </ul>
    </div>
```

```javascript
      var vm = new Vue({
        el: '#app',
        data: {
          mainList: [
            { title: "首页" },
            {
              title: "游戏",
              subList: {
                firstTitle: "斗地主",
                secondTitle: "连连看",
                lastTitle: "植物大战僵尸"
              },
              isShow: false
            },
            {
              title: "音乐",
              subList: {
                firstTitle: "流行",
                secondTitle: "交响乐",
                lastTitle: "乡村音乐"
              },
              isShow: false
            },
            {
              title: "体育",
              subList: {
                firstTitle: "足球",
                secondTitle: "篮球",
                lastTitle: "乒乓球"
              },
              isShow: false
            },
            {
              title: "影视",
              subList: {
                firstTitle: "恐怖",
                secondTitle: "喜剧",
                lastTitle: "爱情"
              },
              isShow: false
            }
          ]
        },
        methods: {
          showSubList: function(e){
            this.showIdx && this.clearPreShow();
            this.showIdx = e.currentTarget.dataset.idx;
            this.mainList[this.showIdx].isShow = true;
          },
          clearPreShow: function(){
            this.mainList[this.showIdx].isShow = false;
          }
        }
      })
```

###### v-text,v-html

* `v-text`: 更新元素的textContent。
* `v-html`: 更新元素的 innerHTML。内容按普通 HTML 插入——数据绑定被忽略。如果想复用模板片断，应当使用 partials。

###### v-bind

v-bind 指令用于响应更新HTML特性，将一个或多个attribute，或者一个组件 prop 动态绑定到表达式，需要把要更新的属性作为参数放在指令之后，如 `v-bing:src`,`:class`(简写)。

```html
      <img v-bind:src="http://xx.yixuan.com/head.jpg"/>
      <div :class="bind-con"></div>
      <custom-component :prop="msg"></custom-component>
```

> 在绑定 `prop` 时，`prop` 需要在子组件内声明。

v-bind后还可以添加修饰符

* `.sync`: 双向绑定，只能用于 `prop` 绑定。2.0被废弃。
* `.once`: 单向绑定，只能用于 `prop` 绑定。2.0被废弃。
* `.camel`: 将绑定的特性名转为用驼峰命名的方式命名。

> `.sync`和`.once`被废弃是因为这种方式虽然方便但是不利于项目的维护。


###### v-on

`v-on` 指令用于绑定事件监听器，需要把事件类型作为参数放在指令之后，表达式可以是一个方法的名字或一个内联语句，如果没有修饰符也可以省略。
用在普通元素上时，只能监听原生 DOM 事件。用在自定义元素组件上时，也可以监听子组件触发的自定义事件。
在监听原生 DOM 事件时，方法以事件为唯一的参数。如果使用内联语句，语句可以访问一个 $event 属性

```html
      <button v-on:click="clickHandlePlay($event)">start</button>
```

1.0.11+ 在监听自定义事件时，内联语句可以访问一个 `$arguments` 属性，它是一个数组，包含传给子组件的 `$emit` 回调的参数。

* `.stop` - 调用 `event.stopPropagation()`。
* `.prevent` - 调用 `event.preventDefault()`。
* `.capture` - 添加事件侦听器时使用 capture 模式。
* `.self` - 只当事件是从侦听器绑定的元素本身触发时才触发回调。
* `.{keyCode | keyAlias}` - 只在指定按键上触发回调。

###### v-ref,v-el,v-pre,v-cloak

略。。。。

### 自定义指令