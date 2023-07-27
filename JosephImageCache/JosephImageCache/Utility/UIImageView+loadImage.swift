//
//  UIImageView+loadImage.swift
//  JosephImageCache
//
//  Created by 차요셉 on 2023/07/27.
//

import UIKit

import RxSwift

extension UIImageView {
    func loadImage(_ urlString: String) -> Single<Data> {
        return JosephImageCache.shared.setImage(imageView: self, imageURLString: urlString)
    }
    
    func cancelImageLoading() {
        JosephImageCache.shared.cancelDataTask(imageView: self)
    }
}
