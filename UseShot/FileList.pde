import java.io.*;
import java.awt.Graphics;
import java.awt.Image;
//import java.awt.image.BufferedImage;

private String[] fileArray;

public class FileList {
	public FileList(String filePath) {
//		String filePath = "/Users/kawasemi/Desktop/dsd";
		filePath = filePath.substring(0,filePath.length()-1);
		File directory1 = new File(filePath);
		fileArray = directory1.list();
		//		if (fileArray != null) {
		//			for(int i = 0; i < fileArray.length; i++) {
		//				if (fileArray[i].endsWith(".dsd")) {// 後方一致（接尾辞）です
		//					System.out.println("スケッチデータです "+fileArray[i]);
		//				}else if (fileArray[i].endsWith(".png")) {
		//					System.out.println("画像です "+fileArray[i]);
		//					//TODO : 画像を読み込む
		//					Image img;
		//					//					String path = filePath+"/"+fileArray[i];
		//					//					img = getImage(getCodeBase(), path);
		//
		//					//TODO : サムネイルを表示する
		//
		//				}else{
		//					System.out.println(fileArray[i]);
		//
		//				}
		//			}
		//		} else{
		//			System.out.println(directory1.toString() + "　は存在しません" );
		//		}
	}
	public String[] getFileList(){
		return fileArray;
	}
}