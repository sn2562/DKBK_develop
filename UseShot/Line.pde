public class DT extends ArrayList<PVector> {//Data
	private color c;//線の色
	private int w;//線の太さ
	public DT(color c, int w) {
		this.c=c;
		this.w=w;
	}

	public int beginShape() {//beginShapeのモードをreturnする。-1の時beginShape()それ以外の時はbeginShape(返り値)となる
		return -1;
	}
	public boolean ableDraw() {//描画可能か
		return size()>1;//線を構成するためには2点以上必要
	}
	public boolean ableCut() {//切断可能か
		return size()>1;
	}
	public int getSaveMode() {//セーブする際のふり番号 Line(0) Spray(1) 保存しない(-1)
		return -1;
	}

	//各種ゲッターとセッター
	public void setColor(color c) {
		this.c=c;
	}
	public void setWeight(int w) {
		this.w=w;
	}
	public void setData(color c, int w) {
		setColor(c);
		setWeight(w);
	}
	public color getColor() {
		return c;
	}
	public color getWeight() {
		return w;
	}
}

public class Cut extends DT {
	private int n;//何番目の値をカットしたか。
	public Cut(color c, int w, int n) {
		super(c, w);
		this.n=n;
	}
	public int getN() {
		return n;
	}

	public boolean ableDraw() {//単なるデータなので絶対描画,切断しない
		return false;
	}
	public boolean ableCut() {
		return false;
	}
}

public class Spray extends DT {
	public Spray(color c, int w) {
		super(c, w);
	}
	public int beginShape() {
		return POINTS;
	}
	public boolean ableCut() {//スプレーは絶対切断できない
		return false;
	}
	public int getSaveMode() {
		return 1;
	}
}

public class Line extends DT implements Serializable {
	public Line(color c, int w) {
		super(c, w);
	}
	public int getSaveMode() {
		return 0;
	}
	PVector p1=new PVector();

	public boolean add(PVector p) {
		super.add(p);
		float px, py, pz;
		//平滑化_smoothing 
		//これはペンモードの場合のみ動かしたい//ペンBの時もやる
		if (tool.nowToolNumber==0||tool.nowToolNumber==1) {
			if (size()==3) {
				p1.set(get(size()-2));//p1に二番目を保存する

				//平均を取る
				px=(get(size()-3).x+get(size()-1).x)/2;
				py=(get(size()-3).y+get(size()-1).y)/2;
				pz=(get(size()-3).z+get(size()-1).z)/2;

				get(size()-2).set(px, py, pz);//値を書き換える
			} else if (size()>3) {
				//p1を使って先に平均をとる
				px=(p1.x+get(size()-1).x)/2;//配列の一番最後の点と比較
				py=(p1.y+get(size()-1).y)/2;
				pz=(p1.z+get(size()-1).z)/2;

				p1.set(get(size()-2));//p1に新しい値を保存しておく
				get(size()-2).set(px, py, pz);//値を書き換える
			}
		}

		return true;
	}
	
	public PVector getLine(){
		return p1;
	}
}
