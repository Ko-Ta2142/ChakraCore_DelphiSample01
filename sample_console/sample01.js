//  アプリケーションによる拡張定義をインポート

var g_value = "global value :)";
var g_array = [1,2,3,4,5,6];
var g_int = 0;

function main() {
    return "hello world :)";
}

//dsnfkjssnfkjsmdljkdss()dfslkdlas;     // JsErrorScriptComple sample

function callback_test(s) {
    imp_print("callback_test.call:" + s);
    //imp_print("callback_test.call:" + s + o.a);     //JsErrorScriptException sample
}

function array_test() {
    //imp_print(g_int.toString());
    for(var value of g_array){
            imp_print( value.toString() );
    }
    imp_print(typeof(g_class));
}

//return main();    //returnすると上の更に上に投げてしまうみたいで取得出来ません
main();
