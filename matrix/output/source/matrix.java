import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class matrix extends PApplet {

//processing-java --run --sketch=/Users/kawasemi/Documents/Processing/DKBK_develop/matrix --output=/Users/kawasemi/Documents/Processing/DKBK_develop/matrix/output --force

public void setup(){
	size(100,100);
	noLoop();
}

public void draw(){



	float rotX = PI;
	PVector px = new PVector(0,0,1);

	println(px);
	println(
		calcRotate(px,
				   1, 0, 0, 0, 
				   0, cos(rotX), sin(rotX), 0, 
				   0, -sin(rotX), cos(rotX), 0, 
				   0, 0, 0, 1)
	);//X\u8ef8\u65b9\u5411\u3067\u56de\u8ee2\u3059\u308b	

	float rotY = PI;
	PVector py = new PVector(1,0,0);
	println(py);
	println(
		calcRotate(py,
				   cos(rotY), 0, sin(rotY), 0, 
				   0,  1, 0, 0, 
				   -sin(rotY),0, cos(rotY), 0, 
				   0, 0, 0, 1)
	);//y\u8ef8\u65b9\u5411\u3067\u56de\u8ee2\u3059\u308b	

	float rotZ = PI;
	PVector pz = new PVector(1,1,0);
	println(pz);
	println(
		calcRotate(pz,
				   cos(rotZ),-sin(rotZ),0, 0, 
				   sin(rotZ), cos(rotZ), 0, 0, 
				   0, 0, 1, 0, 
				   0, 0, 0, 1)
	);//z\u8ef8\u65b9\u5411\u3067\u56de\u8ee2\u3059\u308b
	
	
	
	
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



//\u56de\u8ee2
private PVector calcRotate(PVector p,
						   float m00, float m01, float m02, float m03, 
						   float m10, float m11, float m12, float m13, 
						   float m20, float m21, float m22, float m23, 
						   float m30, float m31, float m32, float m33) {
	PVector calcP=new PVector();//\u8fd4\u3059\u7528

	//\u30d9\u30af\u30c8\u30ebp\u306f(p.x,p.y,p.z,1)\u3068\u3057\u3066\u8a08\u7b97\u3059\u308b
	calcP.x=p.x*m00 + p.y*m01 + p.z*m02 + 1*m03;//x\u5ea7\u6a19
	calcP.y=p.x*m10 + p.y*m11 + p.z*m12 + 1*m13;//x\u5ea7\u6a19
	calcP.z=p.x*m20 + p.y*m21 + p.z*m22 + 1*m23;//x\u5ea7\u6a19
	return calcP;
}

//\u5e73\u884c\u79fb\u52d5
private PVector calcTranslate(PVector p, PVector pos){
	//\u5e73\u884c\u79fb\u52d5 oK
	p.x = p.x + pos.x;
	p.y = p.y + pos.y;
	p.z = p.z + pos.z;
	return p;
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "matrix" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
