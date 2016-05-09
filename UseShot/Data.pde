//撮影したら自動保存
// path/Users/kawasemi/Dropbox/intraction/***.dsd
//

import java.awt.FileDialog;
import java.io.*;

public class Data {//DepthDatadrawを並列処理にすれば軽くなるか？
	private PVector pos;
	private float rotX, rotY, rotZ;//回転量
	private int draw_mode;//写真と線を表示(0) 線だけ表示(1) 深度と線を表示(2) 表示なし(3) 

	private PImage img;
	private int [] depthMap;
	private PVector[] realWorldMap, realWorldMap_back;
	private ArrayList<DT> lines, undo;

	int repoint;//補正を開始した場所(添字)

	public boolean loadAbled=false;//ロードに成功したかどうか。falseのときArrayList<Data>から削除する
	public boolean defaultData=false;//空のデータであるかどうか。
	public boolean shouldupdate=false;//回転、移動等したかどうか。射影するときに使う
	private float RotateMatrix[]=new float[16];//X軸での回転のための行列

	private PVector[] projectionMap;//projectionMapは回転後を見るために使う
	public String dataname="";

	//	private String Savepath = "/Users/kawasemi/Desktop/dsdData/";//mac版/選択したファイル

	//private String Savepath="C:\\Users\\imlab\\Desktop\\dsdData\\kikuchi"+year()+month()+day()+hour()+"_"+minute()+"_"+second()+".dsd";//windows版
	//private String Savepath="C:\\Users\\sumi_000\\Desktop\\dsdData\\oikawa"+year()+month()+day()+hour()+"_"+minute()+"_"+second()+".dsd";//windows版

	private void ready() {
		realWorldMap_back=new PVector[realWorldMap.length];
		projectionMap=new PVector[realWorldMap.length];

		for (int i=0; i<realWorldMap.length; i++) {
			realWorldMap_back[i]=new PVector();
			realWorldMap_back[i].set(realWorldMap[i].x, realWorldMap[i].y, realWorldMap[i].z);

			projectionMap[i]=new PVector();
			projectionMap[i].set(realWorldMap[i].x, realWorldMap[i].y, realWorldMap[i].z);
		}

		undo=new ArrayList<DT>();

		draw_mode=0;
		matrixReset();
	}

	public Data(boolean t) {//空のデータを入れるためのコンストラクタ
		frame.setTitle("DKBK Now Loading...");
		defaultData=true;

		pos=new PVector();
		lines=new ArrayList<DT>();
		PGraphics g=createGraphics(640, 480);//疑似画像を作る
		//    g=createGraphics(width, height);//サイズが640*480意外だとずれる
		g.beginDraw();
		g.background(252, 251, 246);

		/*
    g.rect(0, 0, 100, 100);
     g.rect(g.width, 0, -100, 100);
     g.rect(g.width, g.height, -100, -100);
     g.rect(0, g.height, 100, -100);
     */
		g.endDraw();
		img=g;
		depthMap=new int[img.width*img.height];
		realWorldMap=new PVector[img.width*img.height];
		for (int i=0; i<realWorldMap.length; i++)//深度情報ナシでdepthDataを作成
			realWorldMap[i]=new PVector();

		loadAbled=true;

		ready();
	}

	public Data() {//選択ダイアログを開いて読み込み
		frame.setTitle("DKBK Now Loading...");
		FileDialog fd=new FileDialog(frame, "ファイルを選択してください", FileDialog.LOAD);
		//    fd.setFilenameFilter(getFileExtensionFilter(".dsd"));
		fd.setVisible(true);
		if (fd.getFile()==null||fd.getFile().length()==0)
			return;

		String path=fd.getDirectory()+fd.getFile();
		pos=new PVector();
		lines=new ArrayList<DT>();
		if (!load(path)) return;
		loadAbled=true;

		ready();
	}

	//takeshotのデータをそのまま読み込む
	public Data(PImage timg, int tdepthMap[], PVector[] trealWorldMap) {//takeshotのデータをそのまま読み込む
		println("takeshotのデータをそのまま読み込む");
		//frame.setTitle("DKBK Now Loading...");
		pos=new PVector();
		lines=new ArrayList<DT>();

		loadAbled=true;

		//うけとった要素を代入して初期化
		img=timg;
		depthMap=new int[img.width*img.height];
		realWorldMap=new PVector[img.width*img.height];
		realWorldMap_back=new PVector[img.width*img.height];
		for (int i=0; i<tdepthMap.length; i++) {
			//println("depthmapを再構築");
			depthMap[i]=tdepthMap[i];
		}

		for (int i=0; i<trealWorldMap.length; i++) {
			realWorldMap[i]=trealWorldMap[i];
		}


		for (int i=0; i<realWorldMap.length; i++) {
			realWorldMap_back[i]=new PVector();
			realWorldMap_back[i].set(realWorldMap[i].x, realWorldMap[i].y, realWorldMap[i].z);
		}

		ready();
	}


	public Data(String path) {//パスを直接指定して読み込み
		frame.setTitle("DKBK Now Loading...");
		pos=new PVector();
		lines=new ArrayList<DT>();
		if (!load(path)) return;
		loadAbled=true;
		ready();
	}

	public int getW() {
		return img.width;
	}
	public int getH() {
		return img.height;
	}
	public PVector getVector(int idx) {
		return realWorldMap_back[idx];
	}

	public void draw() {
		color penColor=tool.getPenColor();
		int penW=tool.getPenWeight();
		int penT=tool.getPenTool();

		if (mousePressed) {
			switch(penT) {
				case 1://スプレー
					break;
				case 3://深度スポイト
					float sum=0;
					int x=(int)map(mouseX, 0, width, 0, img.width);//マウスのx座標をイメージ画像上の位置に変換
					int y=(int)map(mouseY, 0, height, 0, img.height);//マウスのy座標をイメージ画像上の位置に変換
					int n=0;//深度が存在した点の数
					for (int iy=-10; iy<=10; iy++)//iy<10まで(まわりの値もとるため)
						for (int ix=-10; ix<=10; ix++) {//ix<10まで(まわりの値もとるため)
							if (0<=x+ix&&x+ix<img.width&&0<=y+iy&&iy+y<img.height) {//画像範囲内のときだけ処理を実行
								//              if (depthMap[(y+iy)*img.width+(x+ix)]!=0) {
								if (realWorldMap[(y+iy)*img.width+(x+ix)].z!=0) {//データがあれば
									//                sum+=depthMap[(y+iy)*img.width+(x+ix)];
									if (mouseButton==LEFT)
										sum+=realWorldMap[(y+iy)*img.width+(x+ix)].z;//もしクリックしたらsum値を変更
									else
										sum+=myScreenZ(realWorldMap[(y+iy)*img.width+(x+ix)].x, realWorldMap[(y+iy)*img.width+(x+ix)].y, realWorldMap[(y+iy)*img.width+(x+ix)].z);
									n++;
								}
							}
						}
					if (n>0) {
						tool.setSpoit(sum/n);//平均値を算出して出力
					}

					break;
			}
		}
	}


	public void redo() {//元に戻す
		if (lines.size()==0)return;
		DT d=lines.get(lines.size()-1);
		if (d.getClass().toString().contains("Cut")) {//最後のがカットデータ
			int n=((Cut)d).getN();
			lines.get(n).addAll(lines.remove(n+1));//前のと後ろのを結合
		}
		undo.add(0, lines.remove(lines.size()-1));
	}
	public void undo() {//やり直し
		if (undo.size()>0)
			lines.add(undo.remove(0));
	}
	public void clear() {//全消去
		lines.clear();
	}
	public void undoclear() {
		undo.clear();
	}

	private void updateMap() {
		if (shouldupdate)
			return;

		if (!shouldupdate)return;
		shouldupdate=false;
		pushMatrix();
		setMatrix();
		for (int i=0; i<realWorldMap.length; i++)
			realWorldMap[i].set(0, 0, 0);
		for (PVector p : realWorldMap_back) {
			if (p.z==0)continue;
			int x=round(map(screenX(p.x, p.y, p.z), 0, width, 0, img.width));
			int y=round(map(screenY(p.x, p.y, p.z), 0, height, 0, img.height));
			if (0<=x&&x<img.width&&0<=y&&y<img.height) {
				int idx=x+y*img.width;
				realWorldMap[idx].set(p.x, p.y, p.z);
			}
		}
		popMatrix();
	}
	public void move(float x, float y) {
		shouldupdate=true;
		switch(tool.nowAxisNumber) {
			case 0:
				pos.x+=x*cos(rotY)+y*sin(rotY);
				pos.z+=x*sin(rotY)-y*cos(rotY);
				break;
			case 1:
				pos.x+=x*cos(rotY);
				pos.z+=x*sin(rotY);
				pos.y+=-y;
				break;
		}
	}
	public void rotate(float dy, float dx, float dz) {
		shouldupdate=true;
		rotX+=dx;
		rotY+=dy;
		rotZ+=dz;
	}
	public void matrixReset() {//移動量をリセットする
		shouldupdate=true;
		pos.set(0, 0, 0);
		rotX=PI;
		rotZ=0;
		rotY=0;
	}
	public boolean isDefaultPosition() {//移動してないかどうか。sinを使っているのは計算誤差を許容するため
		return pos.x==0&&pos.y==0&&pos.z==0&&abs(sin(rotX-PI))<0.01&&abs(sin(rotY-0))<0.01;
	}

	public void setMatrix() {//移動量を反映
		tool.setMatrix();
		translate(width/2, height/2);
		rotateX(rotX);
		rotateY(rotY);
		rotateY(rotZ);
		scale(0.575f*width/img.width);
		translate(0, 0, -1000);
		translate(pos.x, pos.y, pos.z);
	}


	public void cameraupdate(PImage timg, int tdepthMap[], PVector[] trealWorldMap) {
		//frame.setTitle("DKBK Now Loading...");
		pos=new PVector();
		//linesの初期化はしない
		//lines=new ArrayList<DT>();
		//うけとった要素を代入して初期化
		img=timg;
		depthMap=new int[img.width*img.height];
		realWorldMap=new PVector[img.width*img.height];
		realWorldMap_back=new PVector[img.width*img.height];
		for (int i=0; i<tdepthMap.length; i++) {
			//println("depthmapを再構築");
			depthMap[i]=tdepthMap[i];
		}

		for (int i=0; i<trealWorldMap.length; i++) {
			realWorldMap[i]=trealWorldMap[i];
		}

		for (int i=0; i<realWorldMap.length; i++) {
			realWorldMap_back[i]=new PVector();
			realWorldMap_back[i].set(realWorldMap[i].x, realWorldMap[i].y, realWorldMap[i].z);
		}
	}

	public void cameraChangeUpdate(PImage timg, int tdepthMap[], PVector[] trealWorldMap) {
		//現在の値を新しいカメラの値で描き換える

		//frame.setTitle("DKBK Now Loading...");
		pos=new PVector();
		//linesの初期化はしない
		//lines=new ArrayList<DT>();
		//うけとった要素を代入して初期化
		img=timg;
		depthMap=new int[img.width*img.height];
		realWorldMap=new PVector[img.width*img.height];
		realWorldMap_back=new PVector[img.width*img.height];
		for (int i=0; i<tdepthMap.length; i++) {
			//println("depthmapを再構築");
			depthMap[i]=tdepthMap[i];
		}

		for (int i=0; i<trealWorldMap.length; i++) {
			realWorldMap[i]=trealWorldMap[i];
		}

		for (int i=0; i<realWorldMap.length; i++) {
			realWorldMap_back[i]=new PVector();
			realWorldMap_back[i].set(realWorldMap[i].x, realWorldMap[i].y, realWorldMap[i].z);
		}
	}

	public void setCanvasMatrix(PGraphics cv) {//移動量を反映
		cv.translate(data_width/2, data_height/2);
		cv.rotateX(rotX);
		cv.rotateY(rotY);
		cv.rotateY(rotZ);
		cv.scale(0.575f*data_width/img.width);
		cv.translate(0, 0, -1000);
		cv.translate(pos.x, pos.y, pos.z);
	}
	public void updateDKBKCanvas(PGraphics cv, SimpleOpenNI context) {
		pushMatrix();
		//描画モードによって表示内容を変える
		//	0 写真の表示
		//	1 スケッチの表示
		//	2 深度データの表示
		//	3 非表示
		switch(draw_mode){
			case 0:
				cv.hint(DISABLE_DEPTH_TEST);//レンダラを2Dに変える
				//画像を描画-ただし、さっきまで画面に表示されていたカメラの写真に変更されている
				cv.tint(255, 120);//半透明にする
				cv.image(img, 0, 0, cv.width, cv.height);//画像データの表示
				cv.tint(255, 255);//透明度を元に戻す
				cv.hint(ENABLE_DEPTH_TEST);//終了
				break;

			case 1:
				setCanvasMatrix(cv);
				cv.noFill();
				for (DT line : lines) {
					//if (!line.ableDraw())continue;
					cv.stroke(line.c);
					cv.strokeWeight(line.w);
					if (line.beginShape()==-1)
						cv.beginShape();
					else
						cv.beginShape(line.beginShape());
					for (PVector p : line) {
						cv.vertex(p.x, p.y, p.z);
						cv.vertex(p.x, p.y, p.z);//vertex一回だとなぜか線をsize()==2の時なぜか線を書いてくれない
					}
					cv.endShape();
					cv.strokeWeight(1);
				}
				break;

			case 2:
				setCanvasMatrix(cv);
				cv.strokeWeight(4);
				for (int y=0; y < img.height; y+=K) {
					for (int x=0; x < img.width; x+=K) {
						int index = x + y * img.width;
						PVector p=realWorldMap_back[index];
						if (p.z > 0) { 
							cv.stroke(img.pixels[index]);
							cv.point(p.x, p.y, p.z);
						}
					}
				}
				cv.strokeWeight(1);
				break;
			case 3:
				break;
		}
		popMatrix();
	}
	public void addDKBKLine(PGraphics cv,int x,int y){
		if (tool.getPenColorNum()>1) {//色選択
			lines.add(new Line(tool.getPenColor(), tool.getPenWeight()));//色をiconの色に変更

		} else if (tool.getPenColorNum()==0) {//写真スポイト
			tool.penColor[0]=img.get(
				int(map(mouseX, 0, cv.width, 0, img.width)), 
				int(map(mouseY, 0, cv.height, 0, img.height))
			);
			lines.add(new Line(tool.getPenColor(), tool.getPenWeight()));

		} else if (tool.getPenColorNum()==1) {//写真スポイト(ランダム)
			tool.penColor[1]=img.get(
				int(random(0, img.width)), 
				int(random(0, img.height))
			);
			lines.add(new Line(tool.getPenColor(), tool.getPenWeight()));
		}
		undoclear();
	}

	public void addLine() {//太さ、色を指定して新しいlineを追加する
		switch(tool.nowToolNumber) {
			case 0://データとして線を追加
				if (tool.getPenColorNum()>1) {//color cがスポイトじゃないなら
					lines.add(new Line(tool.getPenColor(), tool.getPenWeight()));//色をiconの色に変更
				} else if (tool.getPenColorNum()==0) {//写真スポイト
					tool.penColor[0]=img.get(
						int(map(mouseX, 0, width, 0, img.width)), 
						int(map(mouseY, 0, height, 0, img.height))
					);
					lines.add(new Line(tool.getPenColor(), tool.getPenWeight()));
				} else if (tool.getPenColorNum()==1) {//写真スポイト2.ランダム
					tool.penColor[1]=img.get(
						int(random(0, img.width)), 
						int(random(0, img.height))
					);
					lines.add(new Line(tool.getPenColor(), tool.getPenWeight()));
				}
				undoclear();
				break;
			case 1://データとしてスプレーを追加->線を追加
				//lines.add(new Spray(tool.getPenColor(), tool.getPenWeight()));
				lines.add(new Line(tool.getPenColor(), tool.getPenWeight()));
				undoclear();
				break;
		}
	}

	public boolean moveAble() {
		return draw_mode!=0;
	}
	public void changeDrawMode() {
		draw_mode=(draw_mode+1)%4;
	}

	public void d() {
//		drawLine();
	}

	private void addPoint(PGraphics cv,int x, int y) {//キャンバス上の座標が入る
		try {//たまにArrayIndexOutOfBoundsExceptionでるのでその例外をはじいておく。
//			if (tool.pointOver(x, y)) return;//ツールバーに重なってないなら続ける
			boolean dp=isDefaultPosition();
			x=(int)map(x, 0, cv.width, 0, img.width);//キャンバス上のマウス座標を画像上の位置に変換する
			y=(int)map(y, 0, cv.height, 0, img.height);
			if (x<0||y<0||x>width||y>height)return;//画面外に書いていたら何もしない
			int idx=x+y*img.width;//マウス位置を計算する
			if (idx<0||idx>realWorldMap.length)return;//配列の範囲外だったら何もしない
			PVector p=new PVector();//追加するベクトル
			p.set(realWorldMap_back[idx].x, realWorldMap_back[idx].y, realWorldMap_back[idx].z);

			ArrayList<PVector>line=lines.get(lines.size()-1);//一番最後の線
			if (p.z==0) {
				//if (dp)return;
				//todo 回転操作をしている時もうまく行えるように

				if (!(pos.x==0&&pos.y==0&&pos.z==0&&abs(sin(rotX-PI))<0.01&&abs(sin(rotY-PI))<0.01)) {//もし移動されていたら、位置を計算しなおして入れとく
				} else {
					p=calcRealPoint(LENGTH*5, x, y);
				}
				//println("p.z==0でした");
			}
			if (tool.getSpoit()!=0) {//深度がスポイトしてあるなら
				p=calcRealPoint(tool.getSpoit(), x, y);
			} else {
			}

			//てすと成功
			//println("狂っているかtest:x "+p.x+" y "+p.y+" z "+p.z);//この時点では狂ってない

			/****************** モデル座標-スクリーン座標 *****************

       ****************************************************************/
			//2.作成したprojectionMapからマウスのx,yに対応する点pvを得る

			//回転していてかつスポイトしていないとき
			/*
      if (!(pos.x==0&&pos.y==0&&pos.z==0&&abs(sin(rotX-PI))<0.01&&abs(sin(rotY-PI))<0.01)) {//回転している
       PVector pv = new PVector(projectionMap[idx].x, projectionMap[idx].y, projectionMap[idx].z);
       if (tool.getSpoit()==0) {//スポイトしてない時
       //3. 2で取得できたpv(x,y,z)をunProjectScreenに入れて、モデル内座標を得る
       pv.set(unprojectScreen(pv));
       } else {
       pv.z=tool.getSpoit();//zの値だけスポイトの値に置き換える
       }
       p.set(pv);

       }
       */
			//println("補正前 "+p.x+" "+p.y+" "+p.z);


			//if ((pos.x==0&&pos.y==0&&pos.z==0&&abs(sin(rotX-PI))<0.01&&abs(sin(rotY-PI))<0.01)) {//回転していないなら
			if (line.size()>0&&tool.nowToolNumber==0) {//線を描いていたら,かつ補正ペンなら
				PVector pp=line.get(line.size()-1);
				float ax=pp.x+pos.x;
				float ay=pp.y+pos.y;
				float az=pp.z+pos.z;

				if (new PVector(ax, ay, az).dist(p)>tool.getBorder()) {//距離が大きすぎるようなら前の点の座標のを利用(補正する)
					p=calcRealPoint(az, x, y);
					//補正前と補正後の差　pp-p
					//PVector dpv=PVector.sub(pp, p);//ダブル補正用
					//println("補正前と補正後の差"+dpv);

					//println("追加点 "+p.x+" "+p.y+" "+p.z);
				}
			}
			//      if (line.size()>0&&tool.nowToolNumber==1) {//線を描いていたら,かつ補正ペンBなら
			//        PVector pp=line.get(line.size()-1);
			//        if (pp.dist(p)>tool.getBorder()) {//距離が大きすぎるようなら前の点の座標のを利用(補正する)
			//          p=calcRealPoint(pp.z, x, y);
			//        }
			//      }
			//}

			if (!(pos.x==0&&pos.y==0&&pos.z==0&&abs(sin(rotX-PI))<0.01&&abs(sin(rotY-PI))<0.01)) {//もし移動されていたら、位置を計算しなおして入れとく
				p=reCalcPoint(p);//再計算すると狂う
			} else {
				//println("補正なし");
			}


			if (tool.getPenColorNum()>=4) {//color cがスポイトじゃないなら
				if (tool.getPenWeight()<5) {//細い線なら
					//細い線は手前にずらす
					p.z=p.z-5;
				} else {
					println("太い線");
				}
			}

			line.add(p);//線に点を追加
		}
		catch(Exception e) {
			println(frameCount, x, y);
			e.printStackTrace();
		}
		//println("   end addPoint");
	}

	public void cutLine(int px, int py, int x, int y) {//二次元に射影して、それとマウスの軌跡との交差判定を行い、切断する
		//screenXYを正常に動作させるため、Matrixを描画時と統一する
		pushMatrix();
		setMatrix();

		PVector v1=new PVector(x-px, y-py);
		for (int j=0; j<lines.size (); j++) {
			DT l=lines.get(j);
			if (!l.ableCut())continue;//切れないものは飛ばす。
			ArrayList<PVector> p=l;
			for (int i=1; i<p.size (); i++) {
				PVector p1=p.get(i-1), p2=p.get(i);
				p1=new PVector(p1.x, p1.y, p1.z);
				p2=new PVector(p2.x, p2.y, p2.z);
				p1.set(screenX(p1.x, p1.y, p1.z), screenY(p1.x, p1.y, p1.z), 0);
				p2.set(screenX(p2.x, p2.y, p2.z), screenY(p2.x, p2.y, p2.z), 0);
				PVector v2=new PVector(p2.x-p1.x, p2.y-p1.y);
				if (isCross(new PVector(px, py), v1, p1, v2)) {
					Line rl=new Line(l.c, l.w);//p=切られた左側,rl=切られた右側
					while (p.size ()>i)
						rl.add(p.remove(i));
					lines.add(j+1, rl);//左側の一個後ろに右側を追加
					lines.add(new Cut(l.c, l.w, j));//切断したというデータを残す
					break;
				}
			}
		}

		popMatrix();
	}

	private boolean load(String path) {
		try {
			//もし読み込みファイルが.dsd.pngで終わるようならば.pngを消して読み込みしてみる
			boolean userImage=false;

			if (path.endsWith(".dsd.png")) {
				println("画像の読み込みです");
				path = path.replaceAll(".png", "");
				userImage=true;
			}

			File f=new File(path);

			if (!f.exists()) {
				System.err.println("読み込みに失敗しました。");
				System.err.println(f.getAbsolutePath()+"\nは存在しません。");
				return false;
			}

			if (!f.canRead()) {
				System.err.println("読み込みに失敗しました。");
				System.err.println("読み込むことのできないファイルです。");
				return false;
			}

			String[] splitpath = splitTokens(path, "/");
			println("dataname2 "+splitpath[splitpath.length-1]);
			dataname=splitpath[splitpath.length-1];     


			ObjectInputStream is=new ObjectInputStream(new FileInputStream(f));

			//ファイルからオブジェクトを読み込む
			int w=(Integer)is.readObject();
			int h=(Integer)is.readObject();
			color c[]=(color[])is.readObject();
			depthMap=(int[])is.readObject();
			realWorldMap=(PVector[])is.readObject();
			if (path.endsWith("dsd")) {
				int n=(Integer)is.readObject();
				for (int i=0; i<n; i++) {
					int m=(Integer)is.readObject();
					color cc=(Integer)is.readObject();
					int ww=(Integer)is.readObject();
					DT line=new DT(cc, ww);
					switch(m) {
						case 0:
							line=new Line(cc, ww);
							break;
						case 1:
							line=new Spray(cc, ww);
							break;
					}
					line.addAll((ArrayList<PVector>)is.readObject());
					lines.add(line);
				}
			}

			img=createImage(w, h, ARGB);//画像を扱うためのバッファを作る
			//			println("つくったがぞうさいず"+w+" "+height);
			//img.pixels=c;//バッファの色データを読み込んだオブジェで書き換える
			img.pixels=c;//バッファの色データを読み込んだオブジェで書き換える


			//得られた情報から画像データを作成
			if (userImage) {//選択データが画像だった時
				//img = loadImage(path+".png");
				PImage testImg = loadImage(path+".png");
				testImg.resize(w, h);
				println("画像サイズ "+testImg.width+" "+testImg.height);
				img.pixels=testImg.pixels;
			} else {
				img.pixels=c;
			}

			is.close();//使い終わったら閉める

			return true;
		}
		catch(Exception e) {
			System.err.println("読み込みに失敗しました。");
			e.printStackTrace();
			return false;
		}
	}
	private void save() {
		frame.setTitle("保存中");
		try {
			//FileDialogで読み込みたいファイルを選択する
			FileDialog fd=new FileDialog(frame, "ファイルを選択してください", FileDialog.SAVE);
			fd.setFilenameFilter(getFileExtensionFilter(".dsd"));
			if (debugMode)
				fd.setFile("test.dsd");
			else
				fd.setFile("*.dsd");
			fd.setVisible(true);
			String path=fd.getDirectory()+fd.getFile();//選択したファイル

			//決定が押されてなかったり、ファイル名の長さが0だったりしたら、出力を中断
			if (fd.getFile()==null||fd.getFile().length()==0)
				return;
			if (!path.endsWith("dsd"))//拡張子をdsdに強制
				path+=".dsd";

			ObjectOutputStream os=new ObjectOutputStream(new FileOutputStream(new File(path)));
			println("保存-path"+path);

			//ファイルにオブジェクトを書き込む
			os.writeObject(img.width);
			os.writeObject(img.height);
			img.loadPixels();
			os.writeObject(img.pixels);
			os.writeObject(depthMap);
			os.writeObject(realWorldMap_back);

			int i=0;
			for (DT line : lines) {
				if (line.getSaveMode()==-1)continue;
				i++;
			}
			os.writeObject(i);
			println(i);
			i=0;
			for (DT line : lines) {
				//タイプ(line or spray)//
				int n=line.getSaveMode();
				if (n==-1)continue;
				os.writeObject(n);
				//タイプ//
				os.writeObject(line.getColor());//色
				os.writeObject(line.getWeight());//太さ
				ArrayList<PVector>l=new ArrayList<PVector>();
				l.addAll(line);
				os.writeObject(l);//線データ
				i++;
			}
			println(i);
			os.close();//使い終わったら閉める

			//画像も保存する
			img.save(path+".png");
		}
		catch(Exception e) {
			System.err.println("書き込みに失敗しました。");
			e.printStackTrace();
		}
	}


	private void saveSketch() {//現在開いているスケッチを自動保存
		frame.setTitle("スケッチ保存中");
		try {
			String Savepath2=Savepath+year()+month()+day()+"_"+hour()+minute()+second()+".dsd";//ファイル名に日付と時間を追加
			String path=Savepath2;
			println(path);

			ObjectOutputStream os=new ObjectOutputStream(new FileOutputStream(new File(path)));
			println("保存-path"+path);

			//ファイルにオブジェクトを書き込む
			os.writeObject(img.width);
			os.writeObject(img.height);
			img.loadPixels();
			os.writeObject(img.pixels);
			os.writeObject(depthMap);
			os.writeObject(realWorldMap_back);

			int i=0;
			for (DT line : lines) {
				if (line.getSaveMode()==-1)continue;
				i++;
			}
			os.writeObject(i);
			println(i);
			i=0;
			for (DT line : lines) {
				//タイプ(line or spray)//
				int n=line.getSaveMode();
				if (n==-1)continue;
				os.writeObject(n);
				//タイプ//
				os.writeObject(line.getColor());//色
				os.writeObject(line.getWeight());//太さ
				ArrayList<PVector>l=new ArrayList<PVector>();
				l.addAll(line);
				os.writeObject(l);//線データ
				i++;
			}
			println(i);
			os.close();//使い終わったら閉める

			//現在の画面も保存する
			saveFrame(path+".png");
		}
		catch(Exception e) {
			System.err.println("書き込みに失敗しました。");
			e.printStackTrace();
		}
	}

	private void saveJsonData() {//現在開いているスケッチのデータをjson形式で保存

		JSONObject json;
		json = new JSONObject();

		json.setInt("id", 0);
		json.setInt("imageW", img.width);
		json.setInt("imageH", img.height);

		img.loadPixels();
		String pixelsStr = "";
		int dimension=img.width*img.height;
		for (int i=0; i<dimension; i++) {
			pixelsStr=pixelsStr+img.pixels[i]+" ";
			println(i);
		}
		json.setString("pixels", pixelsStr);
		json.setString("species", "Panthera leo");
		json.setString("name", "Lion");
		saveJSONObject(json, "data/JSONObject.json");
	}


	private void saveJsonArrayData() {//現在開いているスケッチのデータをjson形式で保存
		//JsonObjectをそれぞれ作成して、JsonArrayObjectで管理する
		String[] species = { 
			"Capra hircus", "Panthera pardus", "Equus zebra"
		};
		String[] names = { 
			"Goat", "Leopard", "Zebra"
		};

		JSONObject json;
		JSONArray values = new JSONArray();

		for (int i = 0; i < species.length; i++) {

			JSONObject animal = new JSONObject();

			animal.setInt("id", i);
			animal.setString("species", species[i]);
			animal.setString("name", names[i]);

			values.setJSONObject(i, animal);
		}

		json = new JSONObject();
		json.setJSONArray("animals", values);

		saveJSONObject(json, "data/JSONArray.json");
	}


	PVector calcRealPoint(float z, float x, float y) {//移動量0の時のみZ距離を計算できる関数
		float mag=2*z/LENGTH;
		x=(x-img.width/2)*mag;
		y=(img.height/2-y)*mag;
		return new PVector(x, y, z);
	}



	public float myScreenZ(float x, float y, float z) {//スクリーンからのZ教理を求めようとしてみたやつ。うまくいってない。
		float xx, yy, zz;
		x+=pos.x;
		y+=pos.y;
		z+=pos.z;
		z+=-1000;
		x*=0.575f*width/img.width;
		y*=0.575f*width/img.width;
		z*=0.575f*width/img.width;
		xx=x*cos(rotY)-z*sin(rotY);
		zz=x*sin(rotY)+z*cos(rotY);
		x=xx;
		z=zz;
		yy=y*cos(rotX)-z*sin(rotX);
		zz=y*sin(rotX)+z*cos(rotX);
		z=zz;
		return -z+1200-150;
	}

	private PVector reCalcPoint(PVector recalcP) {//todo 回転後につじつまがあうように再計算する
		PVector ans=new PVector();

		//平行移動 oK
		ans.x=recalcP.x-pos.x;
		ans.y=recalcP.y-pos.y;
		ans.z=recalcP.z-pos.z;
		//回転
		//setRotateMatrixX(cos(radians(rotX)), sin(radians(rotX)), 0, 0, -sin(radians(rotX)), cos(radians(rotX)), 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);//Z軸方向で回転する
		//ans.set(calcRotateX(ans));
		//X軸

		setRotateMatrix(
			1, 0, 0, 0, 
			0, cos(radians(rotX)), sin(radians(rotX)), 0, 
			0, -sin(radians(rotX)), cos(radians(rotX)), 0, 
			0, 0, 0, 1);//X軸方向で回転する

		//ans.set(calcRotateX(ans));
		//Y軸
		setRotateMatrix(cos(radians(rotY)), 0, - sin(radians(rotY)), 0, 0, 1, 0, 0, sin(radians(rotY)), 0, cos(radians(rotY)), 0, 0, 0, 0, 1);//X軸方向で回転する
		//ans.set(calcRotateX(ans));
		//Z軸
		setRotateMatrix(cos(radians(rotZ)), sin(radians(rotZ)), 0, 0, -sin(radians(rotZ)), cos(radians(rotZ)), 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);//X軸方向で回転する
		//ans.set(calcRotateX(ans));
		return ans;
	}

	private PVector calcRotateX(PVector p) {
		//与えられた点を回転して、移動後の位置を返す
		PVector calcP=new PVector();//返す用
		//ベクトルpは(p.x,p.y,p.z,1)として計算する
		calcP.x=p.x*RotateMatrix[0]+p.y*RotateMatrix[4]+p.z*RotateMatrix[8]+1*RotateMatrix[12];//x座標
		calcP.y=p.x*RotateMatrix[1]+p.y*RotateMatrix[5]+p.z*RotateMatrix[9]+1*RotateMatrix[13];//y座標
		calcP.z=p.x*RotateMatrix[2]+p.y*RotateMatrix[6]+p.z*RotateMatrix[10]+1*RotateMatrix[14];//y座標
		return calcP;
	}

	private void setRotateMatrix(
		float m00, float m01, float m02, float m03, 
		float m10, float m11, float m12, float m13, 
		float m20, float m21, float m22, float m23, 
		float m30, float m31, float m32, float m33) {

		//移動用の配列を作る
		RotateMatrix[0]=m00;
		RotateMatrix[1]=m01;
		RotateMatrix[2]=m02;
		RotateMatrix[3]=m03;

		RotateMatrix[4]=m10;
		RotateMatrix[5]=m11;
		RotateMatrix[6]=m12;
		RotateMatrix[7]=m13;

		RotateMatrix[8]=m20;
		RotateMatrix[9]=m21;
		RotateMatrix[10]=m22;
		RotateMatrix[11]=m23;

		RotateMatrix[12]=m30;
		RotateMatrix[13]=m31;
		RotateMatrix[14]=m32;
		RotateMatrix[15]=m33;
	}
}

boolean isCross(PVector s1, PVector v1, PVector s2, PVector v2) {//始点s,方向vの線分と線分が交差しているか
	float cross=get_cross(v1, v2);
	if (cross==0)return false;
	PVector v=new PVector(s2.x-s1.x, s2.y-s1.y);
	float t1=get_cross(v, v1)/cross;
	float t2=get_cross(v, v2)/cross;
	return 0<=t1&&t1<=1&&0<=t2&&t2<=1;
}

float get_cross(PVector p1, PVector p2) {//外積を取得
	return p1.x*p2.y-p2.x*p1.y;
}

public static FilenameFilter getFileExtensionFilter(String extension) {//拡張子 extension で filterするためのクラス。
	final String _extension = extension;  
	return new FilenameFilter() {  
		public boolean accept(File file, String name) {  
			boolean ret = name.endsWith(_extension);   
			return ret;
		}
	};
}

/****************** モデル座標-スクリーン座標 *****************
 / projectScreen,unprojectScreenにPVectorをなげると、それぞれ変換する
 ****************************************************************/
// モデル座標をスクリーン座標に変換
PVector projectScreen(PVector v) {
	PMatrix3D m = getModelToScreenMatrix();//変換行列
	PVector p=new PVector();
	p.set(matrixCMult(m, v));

	//y軸方向で変換するちからわざ
	p.y=height-p.y;

	return p;
}

// 行列で変換したベクトル(wで割ったもの)を返す
PVector matrixCMult(PMatrix3D m, PVector v) {
	PVector ov = new PVector();
	ov.x = m.m00*v.x + m.m01*v.y + m.m02*v.z + m.m03;
	ov.y = m.m10*v.x + m.m11*v.y + m.m12*v.z + m.m13;
	ov.z = m.m20*v.x + m.m21*v.y + m.m22*v.z + m.m23;
	float w = m.m30*v.x + m.m31*v.y + m.m32*v.z + m.m33;
	if (w!=0) ov.mult(1.0f / w);
	return ov;
}

// モデル座標->スクリーン座標の計算に使う行列を取得
PMatrix3D getModelToScreenMatrix() {
	PGraphics3D p3d=(PGraphics3D)g;

	PMatrix3D projection = new PMatrix3D();
	projection = p3d.projection;//プロジェクション行列を取得

	PMatrix3D modelview = new PMatrix3D();
	modelview = p3d.modelview;//モデルビュー行列を取得

	PMatrix3D viewport = new PMatrix3D();//ビューポート行列を取得
	viewport.m03 = viewport.m00 = width * 0.5f;//ズレを補正する
	viewport.m13 = viewport.m11 = height * 0.5f;

	PMatrix3D m = new PMatrix3D(modelview);
	m.preApply(projection);
	m.preApply(viewport);
	//m.m11=-m.m11;
	return m;//この行列をかけると変換できる　ハズ
}

// スクリーン座標をモデル座標に変換
PVector unprojectScreen(PVector v) {
	PMatrix3D m = getModelToScreenMatrix();
	m.invert();

	PVector p=new PVector();
	p.set(matrixCMult(m, v));
	//y軸方向で変換するちからわざ
	p.y=height-p.y;

	return p;
}
