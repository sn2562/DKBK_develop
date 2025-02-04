//processing-java --run --sketch=/Users/kawasemi/Documents/Processing/DKBK_develop/UseShot --output=/Users/kawasemi/Documents/Processing/DKBK_develop/UseShot/output --force

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;
import java.awt.event.*;
import processing.event.MouseEvent;
import SimpleOpenNI.*;

String FilePath1;//始めにロードするデータとLキー押した時に読むデータのパスを入れ解くためのやつ(debug用)
boolean debugMode=false;//デバックモードがtrue時は自動的に上記のファイルをロードする。

final int K=2;//深度データ描写の細かさ
final int LENGTH=1145;//デプスデータを格納している配列の大きさ
final int data_width=640;//画像の解像度
final int data_height=480;//画像の解像度

final float screenZoom=1.5;//1.8;//描画範囲の倍率//1.5普段使い//1.2//微調整用

private TakeShot take;//データの保存に利用
private Tool tool;//ツールバー


private boolean pmousePressed;

static ArrayList<Data> data;//扱っているデータを格納しておく場所

static int setLineW;//線の太さ
static int animFrame;//フレームレートに沿ったフレーム数
static int frameset;//
static boolean animation;//アニメーションしてもいいかどうか
static int framecount=5;//設定するフレームカウント

String Savepath ="";
private String dirName = "dsdData";
private String path = "";

Minim minim;//音
AudioPlayer song;

SimpleOpenNI context;//カメラ更新用
static int oldToolNumber;

//DKBKキャンバス表示用
private PGraphics cv;
private	int[] dkbk_canvas = {
	130, 0, int(data_width*screenZoom), int(data_height*screenZoom)
};//キャンバスの位置とサイズ
//ツールバー表示用
//private PGraphics tcv;

float scrollY=0;


String getParentFilePath(String path, int n) {//n階層上のファイルパスを取得
	File f=new File(path);
	for (int i=0; i<n; i++)
		f=f.getParentFile();
	return f.getAbsolutePath();
}

void setup() {
	animFrame=frameset=0;
	animation=false;

	oldToolNumber=0;
	context = new SimpleOpenNI(this);//カメラ更新用
	if (context.isInit() == false) {//カメラが繋がらなかったらデバッグ用のを読み込む
		println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
		println("カメラ");
		debugMode=true;
	}

	context.setMirror(false);//鏡では表示しない

	//OSチェックと保存パスの設定
	String osname=System.getProperty("os.name").toUpperCase();

	if (osname.matches("^.*MAC.*")) {
		path = sketchPath+"/"+dirName;//Macの場合
		println("Mac");
	} else if (osname.matches("^.*WINDOWS.*")) {
		path = sketchPath+"/"+dirName;//Windowsの場合
		println("Win");
	} else {
		path = sketchPath+"/"+dirName;//Macの場合
	}
	File file = new File(path);
	println("path "+path);
	if (file.exists()) {
		System.out.println("既存のdsdDataディレクトリを使用");
	} else {
		System.out.println("dsdDataディレクトリを新しく作成");
		File newfile1 = new File(path);
		newfile1.mkdir();
	}
	Savepath = path+"/";

	frame.setTitle("DKBK");
	size(dkbk_canvas[0]+dkbk_canvas[2]+60, int(480*screenZoom), P3D);
	//線の太さ、初期設定は3
	setLineW=7;

	FilePath1=dataPath("")+"/todai_horiken7.dsd";

	tool=new Tool(width-61, 60)	;//ツールバー tool(x座標,幅)
	take=new TakeShot(this);//テイクショット

	//初期データの読み込み
	data=new ArrayList<Data>();
	if (debugMode) {
		data.add(new Data(FilePath1));//デバック用のデータ読み込み
		//    data.get(1).changeDrawMode();
	} else {
		data.add(new Data(true));//空のデータを入れておく
	}
	pmousePressed=false;

	//シャッター音源
	minim = new Minim( this );
	song = minim.loadFile( "CameraFlash.wav" );

	//Depth表示用キャンバスの作成
	cv = createGraphics(data_width, data_height, P3D);

	//通信
	myclient = new MyClient(this);
}

void draw() {
	//背景
	background(252, 251, 246);

	//タイトル設定
	frame.setTitle(String.format("DKBK speed:%03d/100 ID:%d member:%d", 
								 round(100*frameRate/60), 
								 myclient.client_id, 
								 myclient.friends.size()));

	frame.setTitle(data.get(tool.nowDataNumber).dataname+" "+round(frameRate));//
	//フレームの計算
	if (tool.animMode()) {
		//アニメーション用フレームレート
		animFrame++;
		frameset=(animFrame-1)/framecount;
		//表示するデータ番号を出力
		//tool.nowDataNumberを変更する
		tool.nowDataNumber=frameset%data.size();

		//表示するデータを変更する draw_modeは0~3
		for (int i=0; i<data.size (); i++) {
			if (i==tool.nowDataNumber)//選択中のデータならば
				data.get(i).draw_mode=1;//0番の表示方法にあわせて表示
			else//それ以外
				data.get(i).draw_mode=3;//非表示
		}
	}

	tool.update();//ツールバーを更新

	if (!tool.isDragged&&!tool.isDragged2) {//ツールバーに重なってないのなら
		//		data.get(tool.nowDataNumber).draw();//線を描く
	}

	if (tool.getMode()) {//trueでUseShotMode,falseでTakeShotMode
		context.update();//カメラ更新用
		//data内のデータを書き換える
		// data.get(tool.nowDataNumber).cameraChangeUpdate();

		//DKBKキャンバスの描画
		cv.beginDraw();
		float z0 = (data_height/2)/tan(PI/8);//tan(radian(45/2))を使うと、微妙に数字がズレるのでダメ
		cv.background(252, 251, 246);//キャンバス背景色
		cv.perspective(PI/4, float(data_width)/float(data_height), 10, 150000);//視野角は45度
		cv.camera(data_width/2, data_height/2, z0, data_width/2, data_height/2, 0, 0, 1, 0);
		data.get(tool.nowDataNumber).updateDKBKCanvas(cv, context);//キャンバスの表示内容を設定
		cv.endDraw();

		//通信中のクライアントの内容を描画
		myclient.update(cv);//通信用のクライアントを更新



		for (int i=0; i<data.size (); i++) {//各種データの操作と描画
			//			data.get(i).update();

			if (tool.getMovMode()) {//trueで静止画モード,falseで動画モード
			} else {
				take.draw();
				take.save();//更新する
			}
		}
	} else {//takeshot
		take.draw();
	}


	hint(DISABLE_DEPTH_TEST);//レンダラを2Dに変える
	image(cv, dkbk_canvas[0], dkbk_canvas[1], dkbk_canvas[2], dkbk_canvas[3]);//キャンバスを描画
	tool.draw();//ツールバーを描画
	hint(ENABLE_DEPTH_TEST);//終了
	pmousePressed=mousePressed;
}

void mousePressed() {
	if (tool.getMode()) {
	} else {//ツールバーに重なっていたら
		take.mousePressed();
	}

	if (tool.pointOver(mouseX, mouseY)) {//ツールバーに重なっている時
		//println("重なってる");
		/*
    if (oldToolNumber==tool.nowToolNumber) {//もし複数回クリックならば
     println("複数回クリック:number"+oldToolNumber);
     //data.get(tool.nowDataNumber).changeDrawMode();
     }
     */
	}

	if (mouseX>dkbk_canvas[0] && mouseX<dkbk_canvas[0]+dkbk_canvas[2] && 
		mouseY>dkbk_canvas[1] && mouseY<dkbk_canvas[1]+dkbk_canvas[3]) {//DKBKキャンバス上ならば
		if (tool.getMode()) {//UseShotモード
			data.get(tool.nowDataNumber).addDKBKLine(cv);//新しい線を追加
		}
	}
}

void mouseWheel(MouseEvent event) {
	if (mouseX<100) {
		float e = event.getCount();
		if (scrollY<0) {
			scrollY = scrollY+e;
		} else {
			scrollY = -1;
		}
	}
}

void mouseReleased() {
	//回転操作をリセットする
	if ( mouseButton == RIGHT ) {
		if (!tool.moveWriter)
			data.get(tool.nowDataNumber).matrixReset();
		else
			tool.matrixReset();
	}
}

void keyReleased(java.awt.event.KeyEvent e) {
	if (tool.getMode()) {
		super.keyReleased(e);//keyCodeやらを更新するために必要
		switch(e.getKeyCode()) {
			case LEFT:
			case UP:
			case RIGHT:
			case DOWN:
			case '0'://do
				//if (data.get(tool.nowDataNumber).moveAble())
				//data.get(tool.nowDataNumber).updateMap();//移動ボタンを離した時に射影しなおす
		}
	}
}

//マウスの操作
void mouseDragged() {
	if (mouseX>dkbk_canvas[0] && mouseX<dkbk_canvas[0]+dkbk_canvas[2] && 
		mouseY>dkbk_canvas[1] && mouseY<dkbk_canvas[1]+dkbk_canvas[3]) {//DKBKキャンバス上ならば
		if (tool.getMode()) {
			if (!tool.isDragged&&!tool.isDragged2) {//ツールバーに重なってないのなら

				//領域上の座標をキャンバス上の座標に変換する
				int canvas_mx = (int)map(mouseX, dkbk_canvas[0], dkbk_canvas[0]+dkbk_canvas[2], 0, cv.width);
				int canvas_my = (int)map(mouseY, dkbk_canvas[1], dkbk_canvas[1]+dkbk_canvas[3], 0, cv.height);
				switch(tool.nowToolNumber) {
					case 0://補正ペン
						data.get(tool.nowDataNumber).addPoint(cv);
						break;
					case 1://スプレー改
						data.get(tool.nowDataNumber).addPoint(cv);
						break;
					case 2://カッター
						data.get(tool.nowDataNumber).cutLine(pmouseX, pmouseY, mouseX, mouseY);
						break;
				}
			}
		}
	}
	if ( mouseButton == RIGHT ) {//右クリックをしていたら
		//閲覧操作
		//回転か並行かを判定する
		if (!tool.moveMode) {
			//1.shiftが押されているか右クリックなら平行移動
			//平行移動
			if (!tool.moveWriter) {
				data.get(tool.nowDataNumber).move(mouseX-pmouseX, mouseY-pmouseY);
			} else {
				tool.move(mouseX-pmouseX, mouseY-pmouseY);
			}
		} else {
			//2.何もなしなら回転移動
			//回転移動
			if (!tool.moveWriter) {//全体移動
				data.get(tool.nowDataNumber).rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
			} else {//個々
				tool.rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
			}
		}
	} else {//それ以外
		//ツールごとの設定
		if (tool.getMode()) {
			if (!tool.isDragged&&!tool.isDragged2) {//ツールバーに重なっていたらやらない

				switch(tool.nowToolNumber) {
					case 4://移動
						//移動量を出力
						//						data.get(tool.nowDataNumber).printTR();
						//検証用2
						if (keyEvent==null) {//起動直後
							//回転か並行かを判定する
							if (!tool.moveMode) {
								//1.shiftが押されているか右クリックなら平行移動
								//平行移動
								if (!tool.moveWriter) {
									data.get(tool.nowDataNumber).move(mouseX-pmouseX, mouseY-pmouseY);
								} else {
									tool.move(mouseX-pmouseX, mouseY-pmouseY);
								}
							} else {
								//2.何もなしなら回転移動
								//回転移動
								if (!tool.moveWriter) {//全体移動
									data.get(tool.nowDataNumber).rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
								} else {//個々
									tool.rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
								}
							}
						} else if (keyEvent.isShiftDown()||!tool.moveMode) {
							//3.shiftが押されているか右クリックなら平行移動
							//平行移動
							if (!tool.moveWriter) {
								data.get(tool.nowDataNumber).move(mouseX-pmouseX, mouseY-pmouseY);
							} else {
								tool.move(mouseX-pmouseX, mouseY-pmouseY);
							}
						} else {//何もしないなら回転移動
							//4.回転移動
							if (!tool.moveWriter) {//全体移動
								data.get(tool.nowDataNumber).rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
							} else {//個々
								tool.rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
							}
						}
						break;
				}
			}
		}
	}
}

//キーボードの操作
public void keyPressed(java.awt.event.KeyEvent e) {
	if (tool.getMode()) {
		tool.shortCut(e.getKeyCode());
		super.keyPressed(e);
		int dx=0, dy=0;
		switch(e.getKeyCode()) {//移動量を求める
			case LEFT:
				dx=-1;
				break;
			case RIGHT:
				dx=+1;
				break;
			case UP:
				dy=-1;
				break;
			case DOWN:
				dy=+1;
				break;
		}
		switch(e.getKeyCode()) {
			case '0':
				if (!tool.moveWriter)
					data.get(tool.nowDataNumber).matrixReset();
				else
					tool.matrixReset();
				break;
			case LEFT:
			case RIGHT:
			case UP:
			case DOWN://どれかの移動キーが押されているとき
				println("いどう");
				if (data.get(tool.nowDataNumber).moveAble()) {
					if (!tool.moveWriter) {
						if (e.isShiftDown()) {
							data.get(tool.nowDataNumber).rotate(dx*PI/100, dy*PI/100, 0);
						} else {
							data.get(tool.nowDataNumber).move(dx*100, dy*100);
							println("うごけー");
						}
					} else {
						if (e.isShiftDown())
							tool.rotate(dx*PI/100, dy*PI/100, 0);
						else
							tool.move(dx*100, dy*100);
					}
				}
				break;
			case DELETE://全消し
				data.get(tool.nowDataNumber).clear();
				break;
			case TAB://ツール表示しなおし
				tool.review();
				break;
			case 'S'://データの描画モードを変更
				data.get(tool.nowDataNumber).changeDrawMode();
				println("描画を変更 "+data.get(tool.nowDataNumber).draw_mode);
				break;
			case 'L'://ロード(debug用)
				if (debugMode&&data.size()==1)
					data.add(new Data(FilePath1));
				break;
			case 'P'://データをpcdとして書き出す
				println("make pcd data");
				//      printPCD();
				//data.get(tool.nowDataNumber).saveJsonData();
				data.get(tool.nowDataNumber).saveJsonArrayData();

				break;

			case'T'://データの撮影
				println("takeShot!");
				take.save();
				break;

			case'A'://アニメーション
				animation=!animation;
				println("animationの切り替え animation:"+animation);
				//println("");
				break;
			case'M':
				uniteAllData();//データマージ
				break;
			default:
				break;
		}
	}
}


void stop() {
	song.close();
	minim.stop();
	super.stop();
}

public void uniteAllData() {
	println("==uniteAllData==");
	Data d=new Data(true);//結合用データ
	if (d.loadAbled) {
		data.add(d);//ロードに成功したときのみリストに追加

		//既に読み込まれているデータの数だけ繰り返す
		for (int i=0; i<data.size ()-1; i++) {
			//回転角と移動量を取り出す
			PVector pos = data.get(i).getTranslateParam();
			PVector rotate = data.get(i).getRotateParam();
			println("pos "+pos+"  rotate "+rotate);

			//lines,色,太さを取り出す
			for (DT line : data.get (i).getLines()) {
				//線を追加
				data.get(data.size()-1).addUniteLine(cv, line.c, line.w);//新しい線を追加

				for (PVector p : line) {
					//座標を変換する
					p=reCalcPoint(p, pos, rotate.x, rotate.y, rotate.z);//再計算すると狂う
					data.get(data.size()-1).addUnitePoint(p);
				}
			}

			//結合用データに追加する
		}
		tool.nowDataNumber=data.size()-1;//現在の操作データを切り替える
	}
}
private PVector reCalcPoint(PVector p, PVector pos, float rotX, float rotY, float rotZ) {
	//一度x軸の回転をリセットする -PI
	//x軸

	//  rotX = rotX-PI;
	//  ans.set(calcRotate(ans, 
	//  1, 0, 0, 0, 
	//  0, cos(rotX), -sin(rotX), 0, 
	//  0, sin(rotX), cos(rotX), 0, 
	//  0, 0, 0, 1));


	//y軸
	//  ans.set(calcRotate(ans, 
	//  cos(rotY), 0, sin(rotY), 0, 
	//  0, 1, 0, 0, 
	//  -sin(rotY), 0, cos(rotY), 0, 
	//  0, 0, 0, 1));
	
	p.set(calcTranslate(p,pos));

	return p;
}

private PVector calcRotate(PVector p, 
						   float m00, float m01, float m02, float m03, 
						   float m10, float m11, float m12, float m13, 
						   float m20, float m21, float m22, float m23, 
						   float m30, float m31, float m32, float m33 ) {

	float RotateMatrix[]=new float[16];//X軸での回転のための行列

	//与えられた点を回転して、移動後の位置を返す
	PVector calcP=new PVector();//返す用

	calcP.x = p.x*m00 + p.y*m01 + p.z*m02 + 1*m03;//x座標
	calcP.y = p.x*m10 + p.y*m11 + p.z*m12 + 1*m13;//y座標
	calcP.z = p.x*m20 + p.y*m21 + p.z*m22 + 1*m23;//z座標

	return calcP;
}

private PVector calcTranslate(PVector p, PVector pos){
	p.x=p.x+pos.x;
	p.y=p.y+pos.y;
	p.z=p.z+pos.z;
	return p;

}