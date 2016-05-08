//import java.awt.*;

public class RoundButton extends Button {//丸ボタン
	public boolean hideButtonLine;
	private PImage img;
	public RoundButton(float x, float y, float w) {//サイズも指定
		super(x, y, w, w);
		hideButtonLine=false;
	}
	public RoundButton(PImage g, float x, float y, float w) {//サイズも指定
		super(x, y, w, w);
		img=g;
		hideButtonLine=false;
	}

	public boolean pointOver(float x, float y) {//点がオブジェクト上にあるか
		//x,yはマウスのxy座標
		float distance = dist(getX(), getY(), x, y);
		return distance<getW();
	}

	//====================//

	public void draw(float x, float y) {
		if (visibility) {
			rectMode(CORNER);
			imageMode(CORNER);
			//      noFill();
			fill(#ffffff);
			stroke(#aaaaaa);
			strokeWeight(2);

			if (selected) 
				fill(#aaaaff, 50+(isMouseOver?50:0));
			if (selected)
				stroke(#4A4B89);
			else if (isMouseOver)
				stroke(#9999AA);
			if (!hideButtonLine||(selected||isMouseOver))
				ellipse(getX(), getY(), getW(), getW());
			image(img, getX()-img.width/2-5, getY()-img.height/2+30, img.width*0.7, img.height*0.7);
			strokeWeight(1);
		}
	}
}


public class Im2Button extends Button {
	PImage img1, img2;
	boolean no;
	public Im2Button(PImage g1, PImage g2, float x, float y) {//サイズは画像通り
		this(g, g2, x, y, g1.width, g1.height);
	}
	public Im2Button(PImage g1, PImage g2, float x, float y, float w, float h) {//サイズも指定
		super(x, y, w, h);
		img1=g1;
		img2=g2;
		no=true;
	}

	public void draw(float x, float y) {
		rectMode(CORNER);
		imageMode(CORNER);
		noFill();
		stroke(#aaaaaa);
		strokeWeight(2);
		if (selected) 
			fill(#aaaaff, 50+(isMouseOver?50:0));
		if (selected||isMouseOver)
			stroke(#3333ff);
		rect(getX(), getY(), getW(), getH());
		image(no?img1:img2, getX(), getY(), getW(), getH());
		strokeWeight(1);
	}
}

public class ImButton extends Button {//イメージ付きボタン
	private PImage img;
	public boolean hideButtonLine;
	public ImButton(PImage g, float x, float y) {//サイズは画像通り
		this(g, x, y, g.width, g.height);
		hideButtonLine=false;
	}
	public ImButton(PImage g, float x, float y, float w, float h) {//サイズも指定
		super(x, y, w, h);
		img=g;
		hideButtonLine=false;
	}



	//====================//

	public void draw(float x, float y) {
		if (visibility) {
			rectMode(CORNER);
			imageMode(CORNER);
			noFill();
			stroke(#aaaaaa);
			strokeWeight(2);
			if (selected) 
				fill(#aaaaff, 50+(isMouseOver?50:0));
			if (selected)
				stroke(#4A4B89);
			else if (isMouseOver)
				stroke(#9999AA);
			if (!hideButtonLine||(selected||isMouseOver))
				rect(getX(), getY(), getW(), getH());
			image(img, getX(), getY(), getW(), getH());
			strokeWeight(1);
		}
	}
}

public class Button extends Obj {//ボタン
	public boolean selected;//選択されているか
	public boolean isMouseOver;//マウスが乗っているか
	public boolean isPressed;//クリックされた瞬間かどうか
	public boolean isReleased;//離された瞬間かどうか
	public boolean visibility;//表示できるかどうか

	public Button(float x, float y, float w, float h) {//ボタンの座標とサイズを指定
		super(x, y, w, h);
		selected=false;
		isMouseOver=false;
		isPressed=false;
		visibility=true;
	}

	public void update(float x, float y) {//ボタンの動作を更新.マウスの座標を引数として与える
		if (!visibility) {
			selected=false;
			isMouseOver=false;
			isPressed=false;
			isReleased=false;
			isReleased=false;
			return;
		}

		isMouseOver=pointOver(x, y);//マウスの座標がボタン上にあるか
		isPressed=pressed();
		isReleased=released();
		if (isPressed)//押された時に選択状態にする
			setSelected(true);
	}

	public void setSelected(boolean t) {//ボタンが選択されているかされていないかを変更する
		selected=t;
	}

	public boolean selected() {
		return selected;
	}

	private boolean pressed() {//押された瞬間であるかどうか
		return isMouseOver&&!pmousePressed&&mousePressed;
	}
	private boolean released() {//離された瞬間であるかどうか
		return pmousePressed&&!mousePressed;
	}
}

public class Obj {//左上を基準点としたオブジェクト
	private float x, y;//座標
	private float cx, cy;//中央座標
	private float w, h;//サイズ

	public Obj(float x, float y, float w, float h) {//オブジェクトの座標とサイズを指定
		this.x=x;
		this.y=y;
		this.h=h;
		this.w=w;
		cx=x+w/2;
		cy=y+h/2;
	}

	public void update(float x, float y) {//abstractなイメージ
	}

	public boolean pointOver(float x, float y) {//点がオブジェクト上にあるか
		return abs(cx-x)<w/2&&abs(cy-y)<h/2;
	}

	public void setPosition(float x, float y) {//座標を設定する
		this.x=x;
		this.y=y;
		cx=x+w/2;
		cy=y+h/2;
	}
	public void addPosition(float dx, float dy) {//座標をずらす
		x+=dx;
		y+=dy;
		cx=x+w/2;
		cy=y+h/2;
	}

	//各種ゲッター
	public float getX() {
		return x;
	}
	public float getY() {
		return y;
	}
	public float getW() {
		return w;
	}
	public float getH() {
		return h;
	}
}

