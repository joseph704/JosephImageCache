//
//  JosephImageCacheError.swift
//  JosephImageCache
//
//  Created by 차요셉 on 2023/07/27.
//

import Foundation

enum JosephImageCacheError: Error {
    case invalidURLError
    case httpURLResponseTypeCastingError
    case httpError
    case imageNotModifiedError
    case networkUsageExceedError
    case unknownNetworkError
}
