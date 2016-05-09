/*
  ID      :ログインしたときのID告知。Serverが送信する。対象者のIDを通知する。
 IN      :誰かがログインしたときの告知。Serverが送信する。現在ログイン中のユーザーのIDを列挙して通知する。
 OK      :IDを登録しデータの受け取り準備ができたときの告知。Clientが送信する。ServerはOKを受け取ったのちに登録されている全データを送信する。
 OUT     :誰かがログアウトしたときの告知。Serverが送信する。ログアウトしたユーザーのIDを通知する。
 GETID   :ID要求。Clientが送信する。
 IMAGE   :画像データを送信する。Clientがたぶん送信する。not used.
 DATA    :深度データを送信する。Clientがたぶん送信する。 not used.
 ADDLINE :線を書き始めたことを通知する。Clientが送信する(Serverも)。線の太さと色を通知する。
 POINT   :線を構成する点が打たれたことを通知する。Clientが送信する(Serverも)。点の座標を通知する。
 TXT     :文字を送信する。テスト用に作っただけ。 not used.
 UNDO    :最後の動作を元に戻す。Clientが送信する(Serverも)。
 DELETE  :データをすべて消す。Clientが送信する(Serverも)。
 NOTFOUND:Order.findで失敗したときに使っている保険。
 */
enum Order {
  ID, 
  IN, 
  OK, 
  OUT, 
  GETID, 
  IMAGE, 
  DATA, 
  ADDLINE, 
  POINT, 
  TXT, 
  UNDO, 
  DELETE, 
  NOTFOUND;

  //文字列をOrderに変換する。stringToOrderとかの名前とかの方がいいかも。
  static public Order find(final String txt) {
    //全てのOrderを探索
    for (Order o : values ()) {
      if (o.toString().equals(txt)) //一致するものがあったら
        return o; //返す
    }

    //見つからなかったら失敗。
    return NOTFOUND;
  }
}

