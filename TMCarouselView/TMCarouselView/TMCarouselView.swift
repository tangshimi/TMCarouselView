//
//  TMCarouseView.swift
//  swiftTest
//
//  Created by tangshimi on 8/5/16.
//  Copyright © 2016 guahao. All rights reserved.
//

import UIKit
import AlamofireImage

typealias DidSelectedClosureType = (_ index: Int) -> Void

private let collectionViewCellID: String = "CollectionViewCell"

class TMCarouselView: UIView {
    var imagesUrl: [String]? {
        didSet {
            showImagesURL = imagesUrl
            if (imagesUrl?.count)! > 1 {
                showImagesURL!.insert((imagesUrl!.last)!, at: 0)
                showImagesURL!.append((imagesUrl!.first)!)
            }
            
            collectionView.reloadData()
            
            if (imagesUrl?.count)! > 1 {
                pageControl.numberOfPages = (imagesUrl?.count)!
                collectionView.scrollToItem(at: IndexPath(row:1, section: 0), at: .centeredHorizontally, animated: false)
                self.showNext()
            }
        }
    }
    
    var didSelectedClosure: DidSelectedClosureType?
    var switchingTime = 4.0
    var defaultImage: String?
    
    fileprivate lazy var collectionView: UICollectionView = {
        let flowViewLayout = UICollectionViewFlowLayout()
        flowViewLayout.scrollDirection = .horizontal
        flowViewLayout.minimumLineSpacing = 0.0
        flowViewLayout.minimumInteritemSpacing = 0.0
        flowViewLayout.itemSize = CGSize(width: self.bounds.width, height: self.bounds.height)
        
        let collectionView = UICollectionView.init(frame: self.bounds, collectionViewLayout: flowViewLayout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TMCarouseViewCollectionViewCell.self, forCellWithReuseIdentifier:collectionViewCellID)
        
        return collectionView
    }()

    fileprivate lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    fileprivate var showImagesURL: [String]?
    fileprivate var nextClosure: Task?
    
    //MARK:init
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
        addSubview(pageControl)
        
        let views = ["pageControl": pageControl]
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[pageControl]-|", options: .alignAllCenterX, metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[pageControl]-0-|", options: .alignAllBottom, metrics: nil, views: views))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:helper
    fileprivate func show() {
        let currentIndex = (collectionView.indexPathsForVisibleItems.first as NSIndexPath?)?.row;
        var nextIndex: Int
        
        nextIndex = currentIndex! + 1
        
        if currentIndex == (showImagesURL?.count)! - 1 {
            nextIndex = 1;
        }
        
        collectionView.scrollToItem(at: IndexPath(row: nextIndex, section: 0), at: .centeredHorizontally, animated: true)
        
        showNext()
    }
    
    fileprivate func showNext() {
        if nextClosure != nil {
            cancel(nextClosure!)
            nextClosure = nil
        }
        
        if (showImagesURL?.count)! > 1 {
            nextClosure = delay(switchingTime, task: { [unowned self] in
                self.show()
            })
        }
    }
    
    //MARK:delay
    typealias Task = (_ cancel: Bool) -> Void

    fileprivate func delay(_ time: TimeInterval, task:@escaping ()->()) -> Task? {
        
        func dispatch_later(_ block:@escaping ()->()) {
            DispatchQueue.main.asyncAfter(
                deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
                execute: block)
        }
        
        var closure: (()->())? = task
        var result: Task?
        
        let delayedClosure: Task = {
            cancel in
            if let internalClosure = closure {
                if (cancel == false) {
                    DispatchQueue.main.async(execute: internalClosure);
                }
            }
            
            closure = nil
            result = nil
        }
        
        result = delayedClosure
        
        dispatch_later {
            if let delayedClosure = result {
                delayedClosure(false)
            }
        }
        
        return result
    }
    
    fileprivate func cancel(_ task:Task?) {
        task?(true)
    }
}

extension TMCarouselView: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    //MARK:UICollectionViewDataSource and UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (showImagesURL != nil) ? showImagesURL!.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellID, for: indexPath) as! TMCarouseViewCollectionViewCell
        if let defaultImage = defaultImage {
            cell.defaultImage = defaultImage
        }

        cell.imageUrl = showImagesURL![(indexPath as NSIndexPath).row]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let didSelectedClosure = didSelectedClosure {
            if (showImagesURL?.count)! > 1 {
                didSelectedClosure((indexPath as NSIndexPath).row - 1)
            } else {
                didSelectedClosure(0)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if nextClosure != nil {
            cancel(nextClosure!)
            nextClosure = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        showNext()
    }
    
    //MARK:UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if nextClosure != nil {
            cancel(nextClosure!)
            nextClosure = nil
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        showNext()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        func changePageControlCurrentIndex(){
            let currentPage: Int = Int(self.collectionView.contentOffset.x / self.frame.width);
            
            if currentPage == 0 {
                self.pageControl.currentPage = showImagesURL!.count;
            } else if currentPage == showImagesURL!.count + 1 {
                self.pageControl.currentPage = 0;
            } else {
                self.pageControl.currentPage = currentPage - 1;
            }
        }
        
        changePageControlCurrentIndex()
        
        if Double(scrollView.contentOffset.x) >= Double(self.frame.width) * Double(showImagesURL!.count - 1) {
            collectionView.scrollToItem(at: IndexPath(row: 1, section: 0), at: .centeredHorizontally, animated: false)
        }
        
        if scrollView.contentOffset.x <= 0 {
            collectionView.scrollToItem(at: IndexPath(row: showImagesURL!.count - 2, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
}


class TMCarouseViewCollectionViewCell: UICollectionViewCell {
    var imageUrl: String? {
        didSet {
            imageView.image = nil
            if let imageurl = imageUrl,
               let url = URL(string: imageurl) {
                if let image = defaultImage {
                    imageView.image = UIImage.init(named: image)
                }
                
                imageView.af_setImage(withURL: url)
            }
        }
    }
    
    var defaultImage: String?
    
    fileprivate lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        
        let views = ["imageView": imageView]
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[imageView]-0-|", options: .alignAllCenterX, metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[imageView]-0-|", options: .alignAllCenterY, metrics: nil, views: views))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

