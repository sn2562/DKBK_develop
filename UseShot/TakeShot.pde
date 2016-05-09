import SimpleOpenNI.*;
import java.io.*;

public class TakeShot {

	SimpleOpenNI context;

	TakeShot(UseShot u) {
		cameraAllow=true;

		context = new SimpleOpenNI(u);

		context.setMirror(false);//鏡では表示しない

		if (context.enableDepth() == false) {//深度センサ使えないなら終了
			System.err.println("Can't open the depthMap, maybe the camera is not connected!");
			cameraAllow=false;
		}

		if (context.enableRGB() == false) {//RGBカメラ使えないなら終了
			System.err.println("Can't open the rgbMap, maybe the camera is not connected or there is no rgbSensor!");
			cameraAllow=false;
		}

		// align depth data to image data
		context.alternativeViewPointDepthToImage();
	}

	PImage img;//画像
	int depthMap[];//深度
	PVector[] realWorldMap;//画面上の点の実際の座標
	boolean cameraAllow;

	//      new Thread(new Mes()).start();
	public class Mes implements Runnable {
		public void run() {
			javax.swing.JOptionPane.showMessageDialog(frame, "マウスクリックで保存します");
		}
	}

	void draw() {
		// update the cam
		context.update();

		//background(252, 251, 246);

		img = context.rgbImage();
		depthMap = context.depthMap();
		realWorldMap = context.depthMapRealWorld();
		hint(DISABLE_DEPTH_TEST);//二次元描画モード
		//半透明にする
		tint(255, 120);
		//image(img, 0, 0, width, height);
		//透明度を元に戻す
		tint(255, 255);

		//マウスの場所の深度データを表示
		int mx=(int)map(mouseX, 0, width, 0, img.width);//マウスのx座標をイメージ画像上の位置に変換
		int my=(int)map(mouseY, 0, height, 0, img.height);//マウスのy座標をイメージ画像上の位置に変換

		int idx=mx+my*context.depthWidth();
		PVector v=realWorldMap[idx];
		//text(depthMap[idx]+"\n"+v.x+", "+v.y+", "+v.z, mouseX, mouseY);
		if (depthMap[idx]==0) {
			text(depthMap[idx], mouseX, mouseY);
		}
		hint(ENABLE_DEPTH_TEST);//終了
	}

	void mousePressed() {//クリックで出力保存

		println("クリック");
		if (tool.pointOver(mouseX, mouseY)) return;//ツールバーに重なってないのなら撮影する
		if (mouseX<0||mouseY<0||mouseX>width||mouseY>height)return;
		String fn=dataPath("mito")+"/"+year()+""+nf(month(), 2, 0)+""+nf(day(), 2, 0);

		try {
			if (!new File(fn).exists())
				new File(fn).mkdir();
		}
		catch(Exception e) {
			e.printStackTrace();
		}

		//save(fn);
		save();
		println("save photo");
	}

	//void save(String path) {
	void save() {
		try {
			//File f=new File(path+"/"+hour()+"_"+minute()+"_"+second());//ファイル名を時分秒にして保存
			//println("保存"+f);
			/*
      ObjectOutputStream os=new ObjectOutputStream(new FileOutputStream(f));

       //ファイルにオブジェクトを書き込む
       os.writeObject(img.width);
       os.writeObject(img.height);
       os.writeObject(img.pixels);
       os.writeObject(depthMap);
       os.writeObject(realWorldMap);

       os.close();//使い終わったら閉める
       */

			//撮ったらすぐに読み込んでスケッチへまわす
			//data.add(new Data(f.getCanonicalPath()));//fのファイルパスをstringに直してdataにaddする
			//data.add(new Data(img, depthMap, realWorldMap));//新しいデータとして保存する
			data.get(tool.nowDataNumber).cameraChangeUpdate(img, depthMap, realWorldMap);//新しいデータとして更新する

			if (data.size()>=2) {//サイズが2以上の時にはデフォルトデータは削除。
				for (int j=0; j<data.size (); j++)
					if (data.get(j).defaultData)
						data.remove(j--);
			}
			//tool.nowDataNumber=data.size()-1;
		}
		catch(Exception e) {
			//ファイルが見つからなかったり、InputStreamの生成に失敗したり、そのたの例外があったら、書き出しを中断。
			e.printStackTrace();
		}
	}
}
