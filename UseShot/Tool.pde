//import java.applet.*;
//import java.awt.*;
public class Tool extends Button {//ツールバー,ボタンをextendsしてるのはmouseOverを楽にとるため
	private Button moveBar;//ドラッグしてツールバーを動かすためのボタン
	private ImButton[] editButton, colorButton, axisButton, toolButton, dataButton, fileButton, thicknessButton;//各種ボタン
	private Im2Button toolButton_chg;//回転用のボタン
	private Im2Button chgButton;//撮影描画切り替えボタン
	private Im2Button movButton;//動画静止画の切り替え
	private ImButton resetMoveButton;//動きの切り替え
	private ImButton animButton;//スケッチのアニメーションボタン
	private ImButton chgCanvasButton;//キャンバス変更ボタン

	private RoundButton takeButton;//撮影用の丸ボタン

	private color[] penColor;//ペン色 ロードした画像データから取得する
	public int nowColorNumber, nowAxisNumber, nowToolNumber, nowDataNumber, nowThicknessNumber;//ボタンの選択状態
	public boolean moveWriter;//全体移動かどうか
	private boolean isDragged, isDragged2;//無印はmoveBarがドラッグされているか.2はthisがドラッグされているか
	private boolean animSketch;
	private float spoit;//深度スポイト
	private int border=100;//補正ペンの自動境界
	public PVector pos;
	public float rotX, rotY, rotZ;
	public int animMode;
	private boolean moveMode;//移動方法,trueのときは回転移

	private int clicknum=0;//クリック回数の記録

	private char keyConfig[];
	float Y;//ツールバーの高さ

	public Tool() {
		super(0, 0, 60, height);//全体の大きさ

		PImage g;
		//最初に選んでおくボタン
		nowColorNumber=0;
		nowAxisNumber=nowToolNumber=nowDataNumber=nowThicknessNumber=0;
		isDragged=isDragged2=moveWriter=false;

		editButton=new ImButton[2];
		colorButton=new ImButton[6];
		axisButton=new ImButton[2];
		toolButton=new ImButton[5];
		dataButton=new ImButton[2];
		fileButton=new ImButton[3];
		thicknessButton=new ImButton[2];

		penColor=new color[colorButton.length];
		pos=new PVector();
		rotX=rotY=rotZ=0;

		//初期設定各種
		moveBar=new Button(0, 0, getW(), 25);

		Y=moveBar.getH()+5;
		for (int i=0; i<editButton.length; i++) {
			g=loadImage("icon-e"+i+".png");
			editButton[i]=new ImButton(g, 6+26*int(i%2), 26*int(i/2)+Y, 24, 24);
		}

		//カラーボタン
		Y+=26*ceil(editButton.length/2.)+13;
		for (int i=0; i<colorButton.length; i++) {
			g=loadImage("icon-c"+i+".png");
			penColor[i]=g.get(0, 0);
			colorButton[i]=new ImButton(g, 6+26*int(i%2), 26*int(i/2)+Y, 24, 24);
		}
		colorButton[0].setSelected(true);//初期状態で選択するボタン

		Y+=26*ceil(colorButton.length/2.)+13;

		//太さボタン
		for (int i=0; i<thicknessButton.length; i++) {
			g=loadImage("icon-thic"+(i)+".png");
			thicknessButton[i]=new ImButton(g, 6, 17*(i)+Y, 48, 15);
		}
		thicknessButton[0].setSelected(true);//初期状態で選択するボタン    
		Y+=17*ceil(thicknessButton.length)+13; 

		//ツールボタン
		for (int i=0; i<toolButton.length; i++) {
			g=loadImage("icon-"+nf(i+3, 2, 0)+".png");
			if (i==3||i==4) {
				println(i+"ツールバーの隙間をうめる");
				toolButton[i]=new ImButton(g, 6, 50*(i-2)+Y, 48, 48);//画像の変化がないボタン
			} else {
				toolButton[i]=new ImButton(g, 6, 50*i+Y, 48, 48);
			}
			toolButton_chg =new Im2Button(loadImage("icon-07_1.png"), loadImage("icon-07.png"), 6, 50*(i-2)+Y, 48, 48);//画像変化のあるボタン
		}
		toolButton[0].setSelected(true);
		//Y+=50*toolButton.length+13;
		Y+=50*3+13;//ツールバーの隙間をうめる

		//回転用YZ軸ボタン
		for (int i=0; i<axisButton.length; i++) {
			g=loadImage("icon-xyz"+(i+1)+".png");
			axisButton[i]=new ImButton(g, 6+26*(i%2), 26*(i/2)+Y, 24, 24);
		}
		axisButton[0].setSelected(true);//初期状態で選択するボタン
		Y+=26*ceil(axisButton.length/2.)+13;
		Y+=26;

		for (int i=0; i<dataButton.length; i++) {
			g=loadImage("icon-m"+i+".png");
			dataButton[i]=new ImButton(g, 6+(getW()-18-6)*i, Y, 12, 24);
		}
		Y+=26*dataButton.length/2+13;
		for (int i=0; i<fileButton.length; i++) {
			g=loadImage("icon-f"+i+".png");
			fileButton[i]=new ImButton(g, 6+26*(i%2), 26*(i/2)+Y, 24, 24);
		}
		Y+=26*ceil(fileButton.length/2.)+13;
		Y+=26;
		//撮影切り替えボタン
		chgButton=new Im2Button(loadImage("icon-cng1.png"), loadImage("icon-cng0.png"), 6, Y, 48, 24);
		movButton=new Im2Button(loadImage("icon-cng1.png"), loadImage("icon-cng0.png"), 6, Y, 48, 24);
		Y=Y+26+13;
		resetMoveButton=new ImButton(loadImage("icon-resetmov.png"), 6, Y, 48, 24);

		Y=Y+26+13;
		animButton=new ImButton(loadImage("icon-anim.png"), 6, Y, 48, 24);

		takeButton = new RoundButton(loadImage("icon-cng1.png"), width-20, 10, 150);

		Y=Y+26+13; 
		chgCanvasButton = new ImButton(loadImage("icon-anim.png"), 6, Y, 48, 24);

		String t[]=loadStrings("system.ini");
		keyConfig=t[0].toCharArray();//キーコンフィグの読み込み


		//最初を静止画から始めるか、動画から始めるか
		movButton.no=true;
		toolButton_chg.no=true;

		moveMode=true;

		//アニメーションの初期設定
		animSketch=false;

		//不可視ボタンの設定
		toolButton[1].visibility=false;
		toolButton[2].visibility=false;
		//toolButton[3].visibility=false;//スポイト
		toolButton[4].visibility=false;

		//ボタンの枠線の設定
		//hideButtonLine
		//moveBar.hideButtonLine=true;
		for (int i=0; i<editButton.length; i++)
			editButton[i].hideButtonLine=true;
		for (int i=2; i<colorButton.length; i++)
			colorButton[i].hideButtonLine=true;
		for (int i=0; i<thicknessButton.length; i++)
			thicknessButton[i].hideButtonLine=true;

		//アニメーションのモードを設定
		animMode=1;
	}

	public void update() {
		super.update(mouseX-getX(), mouseY-getY());
		//ツールバーが押された時の処理
		if (super.isReleased) {
			if (mouseY>Y&&isMouseOver) {//もし複数回クリックならば
				println("複数回クリック:number"+oldToolNumber);
				//        data.get(tool.nowDataNumber).changeDrawMode();
			}
		}

		//moveボタンが押された時の処理とドラッグ状態更新処理
		moveBar.update(mouseX-getX(), mouseY-getY());
		isDragged=moveBar.isPressed||isDragged;
		if (moveBar.isPressed&&mouseButton==RIGHT) {
			review();
		}
		if (moveBar.isReleased)
			isDragged=false;
		if (isDragged&&mouseX-pmouseX!=0)
			addPosition(mouseX-pmouseX, 0);
		isDragged2=isPressed||isDragged2;
		if (isReleased)
			isDragged2=false;

		//各種ボタンが押された時の処理
		for (int i=0; i<editButton.length; i++) {
			editButton[i].update(mouseX-getX(), mouseY-getY());
			if (editButton[i].isPressed) {
				editButton[i].setSelected(false);
				switch(i) {
					case 0://元に戻す
						redo();
						break;
					case 1://やりなおし
						//data.get(nowDataNumber).clear();//全消去
						data.get(tool.nowDataNumber).undo();
						break;
				}
			}
		}
		for (int i=0; i<colorButton.length; i++) {
			colorButton[i].update(mouseX-getX(), mouseY-getY());
			if (colorButton[i].isPressed) {
				nowColorNumber=i;
				buttonSelect(colorButton, i);
			}
		}
		for (int i=0; i<thicknessButton.length; i++) {
			thicknessButton[i].update(mouseX-getX(), mouseY-getY());
			if (thicknessButton[i].isPressed) {
				nowThicknessNumber=i;
				buttonSelect(thicknessButton, i);
			}
		}
		for (int i=0; i<axisButton.length; i++) {
			axisButton[i].update(mouseX-getX(), mouseY-getY());
			if (axisButton[i].isPressed) {
				nowAxisNumber=i;
				buttonSelect(axisButton, i);
			}
		}
		//ツールボタン
		for (int i=0; i<toolButton.length; i++) {
			toolButton[i].update(mouseX-getX(), mouseY-getY());
			if (toolButton[i].isPressed) {
				clicknum=0;
				nowToolNumber=i;
				//data.get(nowDataNumber).updateMap();//do
				buttonSelect(toolButton, i);
				toolButton_chg.setSelected(false);
			}
		}
		if (toolButton[3].isPressed) {
			spoit=0;
		}
		toolButton_chg.update(mouseX-getX(), mouseY-getY());
		if (toolButton_chg.isPressed) {
			clicknum++;//クリック回数を記録
			if (nowToolNumber!=1) { 
				if (clicknum>1) {//ダブルクリックおきに変更する
					toolButton_chg.no=!toolButton_chg.no;
					moveMode=!moveMode;//移動方法を変更する
				}
			}
			toolButton_chg.setSelected(true);
			//moveWriter=!moveWriter;//全体移動、平行移動
			nowToolNumber=4;
			//toolButton[0].setSelected(false);//現在のボタンの選択を解除
			for (int i=0; i<toolButton.length; i++) {
				toolButton[i].setSelected(false);//他のツールボタンの選択を解除
			}
		}

		for (int i=0; i<dataButton.length; i++) {
			dataButton[i].update(mouseX-getX(), mouseY-getY());
			if (dataButton[i].isPressed) {
				dataButton[i].setSelected(false);
				nowDataNumber=nowDataNumber+(i*2-1);
				if (!moveWriter) {
					if (nowDataNumber==-1||nowDataNumber==data.size()) {//全体移動になりそう
						moveWriter=true;
						nowDataNumber=nowDataNumber-(i*2-1);
					}
				} else {//全体移動の時は左右どちらに動いても全体移動でなくなる
					moveWriter=false;
				}
				nowDataNumber=(nowDataNumber+data.size())%data.size();
			}
		}
		for (int i=0; i<fileButton.length; i++) {
			fileButton[i].update(mouseX-getX(), mouseY-getY());
			if (fileButton[i].isPressed) {
				fileButton[i].setSelected(false);
				switch(i) {
					case 0://read
						Data d=new Data();
						if (d.loadAbled) {
							data.add(d);//ロードに成功したときのみリストに追加
							if (data.size()>=2) {//サイズが2以上の時にはデフォルトデータは削除。
								for (int j=0; j<data.size (); j++)
									if (data.get(j).defaultData)
										data.remove(j--);
							}
							nowDataNumber=data.size()-1;
						}
						break;
					case 1://write
						//data.get(nowDataNumber).save();
						//オートセーブに変更
						print("オートセーブ");
						data.get(nowDataNumber).saveSketch();
						break;
					case 2://close
						data.remove(nowDataNumber);
						if (data.size()==0)
							data.add(new Data(true));
						if (nowDataNumber>=data.size())nowDataNumber--;
						break;
				}
				mousePressed=false;//mousePressedがtrueのままになってしまうので強制的にtrueを代入。
			}
		}
		//chgButton.update(mouseX-getX(), mouseY-getY());
		movButton.update(mouseX-getX(), mouseY-getY());

		if (movButton.isPressed) {
			println("カメラ-キャンバスの切り替え");
			movButton.setSelected(false);
			movButton.no=!movButton.no;

			println(movButton.no);
			if (movButton.no) {
				song.rewind();//reload to play
				song.play();//play SE
			}
			if (!movButton.no) movButton.setSelected(true);
			;//枠線をつける
			if (movButton.no) data.get(nowDataNumber).saveSketch();//自動保存
			//写真をとったらツールを鉛筆に変更する
			toolButton[nowToolNumber].setSelected(false);//現在のボタンの選択を解除
			//移動ボタンの表示を非表示に設定
			toolButton_chg.setSelected(false);
			nowToolNumber=0;//ツールを鉛筆に変更
			toolButton[nowToolNumber].setSelected(true);//選択表示を鉛筆に変更

			if (oldToolNumber==tool.nowToolNumber) {//もし複数回クリックならば
				println("切り替えボタン/複数回クリック:number"+oldToolNumber);
			} else {
				UseShot.oldToolNumber=nowToolNumber;
			}
		}


		resetMoveButton.update(mouseX-getX(), mouseY-getY());
		if (resetMoveButton.isPressed) {
			println("リセットボタン");
			if (!tool.moveWriter)
				data.get(tool.nowDataNumber).matrixReset();
			else
				tool.matrixReset();
			resetMoveButton.setSelected(false);
		}

		animButton.update(mouseX-getX(), mouseY-getY());
		if (animButton.isPressed) {
			println("アニメーションボタン"+animSketch);
			//animMode=0;現在の表示にあわせてモードを変える
			animSketch=!animSketch;//押されるたびに切り替え
			if (animSketch) {//アニメーションを行っているとき
				animButton.setSelected(true);//アニメーションボタンを
				moveWriter=true;//全体移動をONにする
			} else {
				animButton.setSelected(false);
				moveWriter=false;//全体移動をOFFにする
			}
		}

		//撮影ボタン
		takeButton.update(mouseX-getX(), mouseY-getY());
		if (takeButton.isPressed) {

			takeButton.setSelected(false);
			println("clicked");

			//=====

			println("カメラ-キャンバスの切り替え");
			movButton.setSelected(false);
			movButton.no=!movButton.no;
			println(movButton.no);
			if (movButton.no) {
				song.rewind();//reload to play
				song.play();//play SE
			}

			if (!movButton.no) movButton.setSelected(true);
			//枠線をつける
			if (movButton.no) data.get(nowDataNumber).saveSketch();//自動保存
			//写真をとったらツールを鉛筆に変更する
			toolButton[nowToolNumber].setSelected(false);//現在のボタンの選択を解除
			//移動ボタンの表示を非表示に設定
			toolButton_chg.setSelected(false);
			nowToolNumber=0;//ツールを鉛筆に変更
			toolButton[nowToolNumber].setSelected(true);//選択表示を鉛筆に変更


			if (oldToolNumber==tool.nowToolNumber) {//もし複数回クリックならば
				println("切り替えボタン/複数回クリック:number"+oldToolNumber);
			} else {
				UseShot.oldToolNumber=nowToolNumber;
			}
		}
		chgCanvasButton.update(mouseX-getX(), mouseY-getY());
		if(chgCanvasButton.isPressed){
			println("キャンバスの表示切り替え");
			if (!tool.moveWriter)
				data.get(tool.nowDataNumber).changeDrawMode();
			else
				tool.matrixReset();
			chgCanvasButton.setSelected(false);


		}

	}

	public void draw() {
		hint(DISABLE_DEPTH_TEST);//二次元描画モード
		if (nowToolNumber==3) {//スポイトの表示
			fill(255);
			rect(mouseX, mouseY, 100, 20);
			fill(0);
			textAlign(CENTER, CENTER);
			text(spoit, mouseX+50, mouseY+10);
		}

		//this=ツールバーの描画
		stroke(0);
		fill(255);
		rect(getX(), getY(), getW(), getH());

		//move量の反映
		pushMatrix();
		translate(getX(), 0);

		//moveBarの描画
		fill(#eeeeee);
		rect(moveBar.getX(), moveBar.getY(), moveBar.getW(), moveBar.getH());

		//各種ボタン描画
		for (int i=0; i<editButton.length; i++)
			editButton[i].draw(mouseX-getX(), mouseY-getY());
		for (int i=0; i<colorButton.length; i++)
			colorButton[i].draw(mouseX-getX(), mouseY-getY());
		for (int i=0; i<thicknessButton.length; i++)
			thicknessButton[i].draw(mouseX-getX(), mouseY-getY());
		for (int i=0; i<axisButton.length; i++)
			axisButton[i].draw(mouseX-getX(), mouseY-getY());
		for (int i=0; i<toolButton.length; i++)
			toolButton[i].draw(mouseX-getX(), mouseY-getY());
		for (int i=0; i<dataButton.length; i++)
			dataButton[i].draw(mouseX-getX(), mouseY-getY());
		for (int i=0; i<fileButton.length; i++)
			fileButton[i].draw(mouseX-getX(), mouseY-getY());
		//chgButton.draw(mouseX-getX(), mouseY-getY());
		movButton.draw(mouseX-getX(), mouseY-getY());
		//chgButton2.draw(mouseX-getX(), mouseY-getY());
		resetMoveButton.draw(mouseX-getX(), mouseY-getY());
		animButton.draw(mouseX-getX(), mouseY-getY());
		toolButton_chg.draw(mouseX-getX(), mouseY-getY());
		takeButton.draw(mouseX-getX(), mouseY-getY());
		chgCanvasButton.draw(mouseX-getX(), mouseY-getY());

		fill(0);
		if (spoit!=0) {//スポイトが0出ない時スポイト量を表示する
			textAlign(CENTER, DOWN);
			text((int)spoit, toolButton[3].getX()+toolButton[3].getW()/2, toolButton[3].getY()+toolButton[3].getH());
		}

		//現在操作しているデータの番号を表示する
		fill(moveWriter?#aaaaaa:0);
		textAlign(CENTER, CENTER);
		text(str(nowDataNumber), getW()/2, dataButton[0].getY()+dataButton[0].getH()/2);

		popMatrix();

		hint(ENABLE_DEPTH_TEST);//終了
	}

	private void buttonSelect(ImButton m[], int n) {//n番目のボタンを選択しn番目以外のボタンの選択を解除する
		for (int i=0; i<n; i++)
			m[i].setSelected(false);
		m[n].setSelected(true);
		for (int i=n+1; i<m.length; i++)
			m[i].setSelected(false);

		print("oldToolNumber :"+oldToolNumber);
		print("tool.nowToolNumber :"+tool.nowToolNumber);
		println("mouseY: "+mouseY+" Y: "+Y);

		if (oldToolNumber==tool.nowToolNumber) {//もし複数回クリックならば
			println("複数回クリック:number"+oldToolNumber);
		} else {
			UseShot.oldToolNumber=nowToolNumber;
		}


		//切り替え
		//println("切り替え");
	}
	private void redo() {
		data.get(nowDataNumber).redo();
	}
	private void undo() {
		data.get(nowDataNumber).undo();
	}

	public void shortCut(int e) {//ショートカットキー
		if (e==keyConfig[0])
			redo();

		else if (e==keyConfig[1])
			undo();
		else if (e==keyConfig[2]);//拡大
		else if (e==keyConfig[3]);//縮小
		else if (e==keyConfig[4]) {//ペン
			buttonSelect(toolButton, 0);
			nowToolNumber=0;
		} else if (e==keyConfig[5]) {//カッター
			buttonSelect(toolButton, 2);
			nowToolNumber=2;
		} else if (e==keyConfig[6]) {//移動
			buttonSelect(toolButton, 4);
			nowToolNumber=4;
		}
	}

	public void review() {//端っこにあわせる
		if (getX()+getW()/2<width/2)
			setPosition(0, 0);
		else
			setPosition(width-getW(), 0);
	}

	//各種ゲッターとセッター
	public void setSpoit(float s) {
		spoit=s;
	}
	public float getSpoit() {
		return spoit;
	}
	public float getBorder() {
		return border;
	}
	public color getPenColor() {
		return penColor[nowColorNumber];
	}
	//int getPenWNum
	public int getPenColorNum() {//現在のペン番号を返す
		return nowColorNumber;
	}
	public int getPenTool() {
		return nowToolNumber;
	}
	public int getPenWeight() {//ペンの太さを返す
		switch(nowThicknessNumber) {
			case 0:
				return 3;
			case 1:
				return 9;
		}
		//return 3;
		return UseShot.setLineW;//ここはいずれボタン?などの画面上で操作する機能として実装する
	}
	public boolean getMode() {//trueでUseMode,falseでTakeMode
		return chgButton.no;
	}
	public boolean getMovMode() {//trueで静止画モード,falseで動画モード
		return movButton.no;
	}
	public boolean animMode() {//アニメーションのモード
		return animSketch;
	}
	public boolean moveMode() {//アニメーションのモード
		return moveMode;
	}


	public int getThicknessNum() {//ペンの太さ
		return nowThicknessNumber;
	}

	public void matrixReset() {//移動量をリセット
		pos.set(0, 0, 0);
		rotX=rotY=rotZ=0;
	}
	public void setMatrix() {//移動量を反映
		rotateX(rotX);
		rotateY(rotY);
		rotateZ(rotZ);
		translate(pos.x, pos.y, pos.z);
	}
	public void rotate(float dx, float dy, float dz) {//回転させる
		rotX+=dy;
		rotY+=dx;
		rotZ+=dz;
	}
	public void move(float x, float y) {//移動させる
		switch(nowAxisNumber) {
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
}

