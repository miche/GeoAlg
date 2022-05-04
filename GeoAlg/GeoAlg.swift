import Foundation
import simd

protocol GeoNum where Storage: SIMD {
    associatedtype Storage
    associatedtype Scalar

    var mv: Storage { get }

//    var reverse: Self { get }
//    var involute: Self { get }
//    var conjugate: Self { get }
//    var dual: Self { get }
//    var inverse: Self { get }
//
//    func geoProd(_ other: Self) -> Self
//    func innerProd(_ other: Self) -> Self
//    func outerProd(_ other: Self) -> Self
//    func regProd(_ other: Self) -> Self
}

protocol GeoAlg: Equatable where GeoStorage: GeoNum {
    associatedtype GeoStorage

    var gn: GeoStorage { get }
}

