//
//  JosephImageCache.swift
//  JosephImageCache
//
//  Created by 차요셉 on 2023/07/27.
//

import UIKit

import RxSwift
import RxCocoa

final class JosephImageCache {
    static let shared: JosephImageCache = .init()
    private let memoryCache: NSCache<NSString, CacheImage> = .init()
    private var dataTaskDictionary: [UIImageView: Disposable] = .init()
    private init() {}
    
    func setImage(
        imageView: UIImageView,
        imageURLString: String
    ) -> Single<Data> {
        guard let imageURL = URL(string: imageURLString) else {
            return Single<Data>.error(JosephImageCacheError.invalidURLError)
        }
        
        if let image = getMemoryCache(imageURLString: imageURLString) {
            return fetchImageFromServer(
                imageView: imageView,
                imageURL: imageURL,
                etag: image.etag
            )
            .map { $0.imageData }
            .catchAndReturn(image.imageData)
        }
        
        return fetchImageFromServer(imageView: imageView, imageURL: imageURL)
            .map { $0.imageData }
    }
    
    func cancelDataTask(imageView: UIImageView) {
        dataTaskDictionary[imageView]?.dispose()
    }
}

private extension JosephImageCache {
    func setMemoryCache(imageURLString: String, cacheImage: CacheImage) {
        memoryCache.setObject(cacheImage, forKey: imageURLString as NSString)
    }
    
    func getMemoryCache(imageURLString: String) -> CacheImage? {
        return memoryCache.object(forKey: imageURLString as NSString)
    }
    
    func fetchImageFromServer(imageView: UIImageView, imageURL: URL, etag: String? = nil) -> Single<CacheImage> {
        return Observable<CacheImage>.create { [weak self] emitter in
            var request = URLRequest(url: imageURL)
            if let etag = etag {
                request.addValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            
            let disposable = URLSession.shared.rx.response(request: request)
                .subscribe(
                    onNext: { (response, data) in
                        switch response.statusCode {
                        case (200...299):
                            let etag = response.allHeaderFields["Etag"] as? String ?? ""
                            let cacheImage = CacheImage(imageData: data, etag: etag)
                            self?.setMemoryCache(
                                imageURLString: imageURL.absoluteString,
                                cacheImage: cacheImage
                            )
                            emitter.onNext(cacheImage)
                        case 304:
                            emitter.onError(JosephImageCacheError.imageNotModifiedError)
                        case 402:
                            emitter.onError(JosephImageCacheError.networkUsageExceedError)
                        default:
                            emitter.onError(JosephImageCacheError.unknownNetworkError)
                        }
                    },
                    onError: { error in
                        emitter.onError(error)
                    }
                )
            
            self?.dataTaskDictionary[imageView] = disposable
            
            return Disposables.create(with: disposable.dispose)
        }
        .asSingle()
    }
}

final class CacheImage {
    let imageData: Data
    let etag: String
    
    init(imageData: Data, etag: String) {
        self.imageData = imageData
        self.etag = etag
    }
}
