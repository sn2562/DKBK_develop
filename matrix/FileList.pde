//processing-java --run --sketch=/Users/kawasemi/Documents/Processing/DKBK_develop/matrix --output=/Users/kawasemi/Documents/Processing/DKBK_develop/matrix/output --force

void setup(){
	size(100,100);
	noLoop();
}

void draw(){



	float rotX = PI;
	PVector px = new PVector(0,0,1);

	println(px);
	println(
		calcRotate(px,
				   1, 0, 0, 0, 
				   0, cos(rotX), sin(rotX), 0, 
				   0, -sin(rotX), cos(rotX), 0, 
				   0, 0, 0, 1)
	);//X軸方向で回転する	

	float rotY = PI;
	PVector py = new PVector(1,0,0);
	println(py);
	println(
		calcRotate(py,
				   cos(rotY), 0, sin(rotY), 0, 
				   0,  1, 0, 0, 
				   -sin(rotY),0, cos(rotY), 0, 
				   0, 0, 0, 1)
	);//y軸方向で回転する	

	float rotZ = PI;
	PVector pz = new PVector(1,1,0);
	println(pz);
	println(
		calcRotate(pz,
				   cos(rotZ),-sin(rotZ),0, 0, 
				   sin(rotZ), cos(rotZ), 0, 0, 
				   0, 0, 1, 0, 
				   0, 0, 0, 1)
	);//z軸方向で回転する
	
	
	
	
	PVector p = new PVector(0,0,1);
	println(p);
	p.set(calcRotate(px,
				   1, 0, 0, 0, 
				   0, cos(rotX), sin(rotX), 0, 
				   0, -sin(rotX), cos(rotX), 0, 
				   0, 0, 0, 1));
	p.set(calcRotate(py,
				   cos(rotY), 0, sin(rotY), 0, 
				   0,  1, 0, 0, 
				   -sin(rotY),0, cos(rotY), 0, 
				   0, 0, 0, 1));
	p.set(calcRotate(pz,
				   cos(rotZ),-sin(rotZ),0, 0, 
				   sin(rotZ), cos(rotZ), 0, 0, 
				   0, 0, 1, 0, 
				   0, 0, 0, 1));
	println(p);
	
}



//回転
private PVector calcRotate(PVector p,
						   float m00, float m01, float m02, float m03, 
						   float m10, float m11, float m12, float m13, 
						   float m20, float m21, float m22, float m23, 
						   float m30, float m31, float m32, float m33) {
	PVector calcP=new PVector();//返す用

	//ベクトルpは(p.x,p.y,p.z,1)として計算する
	calcP.x=p.x*m00 + p.y*m01 + p.z*m02 + 1*m03;//x座標
	calcP.y=p.x*m10 + p.y*m11 + p.z*m12 + 1*m13;//x座標
	calcP.z=p.x*m20 + p.y*m21 + p.z*m22 + 1*m23;//x座標
	return calcP;
}

//平行移動
private PVector calcTranslate(PVector p, PVector pos){
	//平行移動 oK
	p.x = p.x + pos.x;
	p.y = p.y + pos.y;
	p.z = p.z + pos.z;
	return p;
}