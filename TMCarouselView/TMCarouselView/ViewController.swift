//
//  ViewController.swift
//  TMCarouselView
//
//  Created by tangshimi on 27/03/2017.
//  Copyright © 2017 guahao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let carouseView = TMCarouselView.init(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200))
        view.addSubview(carouseView)
        
        carouseView.imagesUrl = [ "https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1491206883&di=3d48025dad428ff2cb8564c58da2377a&imgtype=jpg&er=1&src=http%3A%2F%2Fpic.uuhy.com%2Fuploads%2F2012%2F01%2F10%2FMacro_by_AstridT.jpg", "http://imgstore.cdn.sogou.com/app/a/100540002/714860.jpg", "http://e.hiphotos.baidu.com/image/h%3D200/sign=31e61d6532f33a87816d071af65d1018/95eef01f3a292df504213240b4315c6035a87381.jpg"]
        carouseView.didSelectedClosure = {(index: Int) -> Void in
            print( index)
        }
    }
}

