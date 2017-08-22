# ChakraCore_DelphiSample01
ChakraCore Delphi Implement sample. \
on meemory load,set get value,set call function,set get array,error handling, sample code.\
win32 console application.

ChakraCore.dll による最小構成サンプル。

+ メモリ上読み込み
+ 値の設定と取得
+ 関数の組み込みと呼び出し
+ 配列操作
+ エラーハンドリング

などを行います。

## ChakraCore.dll
各自ご用意ください。win32-releaseで出力した物を使用しています。

<a haref="https://github.com/Microsoft/ChakraCore">https://github.com/Microsoft/ChakraCore</a>

## use library
ChakraCore-Delphiヘッダ（ライブラリ）を使用します。以下よりダウンロードしてライブラリパスを通しておいてください。

<a href="https://github.com/hsreina/ChakraCore-Delphi">https://github.com/hsreina/ChakraCore-Delphi</a>

## fix library
動作させるにはDelphi側で2カ所修正が必要です。


* fix enum size 32bit

初期状態では列挙型が1byteになっています。ChakraCoreでは32bit(int)なのでライブラリファイルの最初にコンパイルマクロを入れてください。
```
// ChakraCommon.pas
unit ChakraCommon;
{$Z4}  // add macro. enum size 32bit. 
```

* fix JsIntToNumber function

参照渡しになっているので以下に修正してください。
```
// ChakraCommon.pas
  function JsIntToNumber(
    intValue : int;         //var intValue : int;        //** fix
    var value: JsValueRef
  ): JsErrorCode; stdcall; external DLL_NAME;
```

## blog
詳しい説明は以下になります。

<a href="http://d.hatena.ne.jp/Ko-Ta/20170821/p1">ChakraCore implement basic</a>

<a href="http://d.hatena.ne.jp/Ko-Ta/20170822/p1">ChakraCore implement error handling</a>
