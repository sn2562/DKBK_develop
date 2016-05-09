import processing.net.*;
import java.awt.*;
import java.awt.event.*;

MyClient myclient;

//MyClientが通信している人のデータを保存するためのクラス。
public class Friend {
  PImage img; //使っていない。
  ArrayList<Line> lines;
  PVector pos; //相手の座標。自分の空間を(0, 0)としたときのxy変移
  int id;

  public Friend(int id) {
    this.id = id;
    //ぐるぐるとぐろを巻くように適当な場所に設置する。
    int D = (id/4+1) * 1000;
    pos = new PVector(D * cos(HALF_PI * id), 0, D*sin(HALF_PI * id));

    img = createImage(600, 480, ARGB);//imgが空だとやばそうなので一応初期化しておく。
    lines = new ArrayList<Line>();
  }

  public void update() {
    pushMatrix();
    tool.setMatrix();
    translate(width/2, height/2);
    //現在選択中のレイヤー分の移動
    rotateX(data.get(tool.nowDataNumber).rotX);
    rotateY(data.get(tool.nowDataNumber).rotY);
    rotateY(data.get(tool.nowDataNumber).rotZ);
    scale(0.575f*width/img.width);
    translate(0, 0, -1000);
    //translate(data.get(tool.nowDataNumber).pos.x, data.get(tool.nowDataNumber).pos.y, data.get(tool.nowDataNumber).pos.z);
    //通信者ごとの適当な場所への変移分の移動
    //translate(pos.x, pos.y, pos.z);

    //描画部分
    noFill();
    for (DT line : lines) {
      stroke(line.c);
      strokeWeight(line.w);
      beginShape();
      for (PVector p : line) {
        vertex(p.x, p.y, p.z);
        vertex(p.x, p.y, p.z);//vertex一回だとなぜか線をsize()==2の時なぜか線を書いてくれない
      }
      endShape();
      strokeWeight(1);
    }

    popMatrix();
  }
}

//実際に通信する役割を持たせているクラス
public class MyClient {
  Client client; //processing.net.Client
  int client_id; //自分のID。
  HashMap<Integer, Friend> friends = new HashMap<Integer, Friend>(); //通信者のデータ群。
  ArrayList<Integer> disconList = new ArrayList<Integer>(); //切断が発生した人たちのリスト。この方式を取らないと拡張for文の途中で消しましたエラーが発生する。
  final String IP_ADDRESS = null; //中じゃなくて外と通信するときはここにServerのIPを入れると楽。
  //ex. final String IP_ADDRESS = "192.168.0.0";
  final String LOCAL = "127.0.0.1";

  public MyClient(PApplet ap) {
    client_id=-1;
    client=new Client(ap, IP_ADDRESS == null ? LOCAL : IP_ADDRESS, 8181);
    if (!client.active())
      println("接続に失敗。サーバーの起動と設定を確認してくだし");
    else {
      println("接続に成功しました");
    }
  }

  public void update() {
    if (!client.active()) return; //接続に失敗していた時には処理を行わない。
    while (client.available ()>0) {//受信するデータを受け取る。
      if (!receiveData(client))break;
    }
    if (client_id == -1) { //IDがないときはID要求
      write("GETID");
      return;
    }

    while (!disconList.isEmpty ()) { //切断された人がいたら、確実のfor文の外の保証があるここで削除する。
      friends.remove(disconList.remove(0));
    }

    for (Integer id : friends.keySet ()) friends.get(id).update();
  }

  void write(Object order, Object... obj) {//Serverにデータを書き込む
    if (!client.active()) return; //接続に失敗していた時には処理を行わない。
    if (tool.nowDataNumber != 0) return;//0 番じゃない時はデータを送信しない。
    StringBuffer sb=new StringBuffer();
    sb.append(order.toString());
    sb.append(":"+client_id);
    for (Object o : obj)
      sb.append(":"+o.toString());
    sb.append('\n');

    client.write(sb.toString());
  }

  boolean receiveData(Client client) {//次のデータを読み込む必要性がある可能性があるときにtrueを返す
    String receive=client.readStringUntil('\n');//クライアントから送られてきた情報
    if (receive==null) {
      println("isNULL");
      return false;//送り途中なら待つ
    }

    receive=receive.replace("\n", "");//改行コードを消しちゃう

    //    println(receive+"::on client"+client_id+"  "+frameCount);

    String input[]=receive.split(":");//':'で区切る
    Order order=Order.find(input[0]);
    int id=input.length>1?int(input[1]):-1;

    switch(order) {
    case ID:
      if (client_id == -1) {
        if (!friends.containsKey(id)) {
          friends.put(id, new Friend(id));
        }
        client_id=id;
        write(order.OK.toString());

        /*
        //初めにサーバーにデータを送るための部分。
         for (DT l : data.get (0).lines) {
         write("ADDLINE", l.c, l.w);
         for (PVector p : l) {
         write("POINT", p.x+","+p.y+","+p.z);
         }
         }
         */
      }
      break;
    case IN:
      //新しくログインした人がいるなら追加する。
      for (int i=2; i<input.length; i++) {
        if (!friends.containsKey(input[i])) {//既に登録済みの人でないなら
          int id_ = int(input[i]);
          friends.put(id_, new Friend(id_));
        }
      }
      break;
    case OUT:
      disconList.add(id);
      break;
    case ADDLINE:
      if (id==client_id)break;//一応の保険。
      friends.get(id).lines.add(new Line(int(input[2]), int(input[3])));
      break;
    case POINT:
      if (id==client_id)break;
      String pString[]=input[2].split(",");
      PVector p=new PVector(float(pString[0]), float(pString[1]), float(pString[2]));
      ArrayList<Line> lines = friends.get(id).lines;
      lines.get(lines.size()-1).add(p);
      break;
    case UNDO:
      if (id==client_id)break;
      if (friends.get(id).lines.size()>0)
        friends.get(id).lines.remove(friends.get(id).lines.size()-1);
      break;
      case DELETE:
        friends.get(id).lines.clear();
      break;
    default:
      break;
    }

    if (client_id==-1)write("GETID");//IDを持っていないのにデータ送信をされているようなら要求する

    return true;
  }

  public void addLine(int penColor, int penWeight) {
    write(Order.ADDLINE, penColor, penWeight);
  }

  public void addPoint(PVector p) {
    write(Order.POINT, p.x+","+p.y+","+p.z);
  }

  public void undo() {
    write(Order.UNDO);
  }

  public void delete() {
    write(Order.DELETE);
  }
}

//==========意味ないと思う。消してもいいかもしれない。===============//
void serverEvent(Server server, Client client) {
  println("server Event::on client"+myclient.client_id);
}

void clientEvent(Client client) {
  //  println("client Event::on client"+client_id);
  //  myclient.receiveData(client);
}

void disconnectEvent(Client client) {
  println("discon Event::on client"+myclient.client_id);
}
//==========意味ないと思う。消してもいいかもしれない。===============//

