import Foundation
import simd

/// 3D PGA
struct R301: GeoNum {
    typealias Scalar = Double
    typealias Storage = SIMD8<Scalar>
    enum GeoNumTypes {
        case plane          //    e1,   e2,   e3    e0
        case hyperbolic     // s, e1                                     (R1)
        case dual           // s,                   e0                   (R001)

        case point          //    e032, e013, e021, e123
        case direction      //    e032, e013, e021

        case line           //    e01,  e02,  e03,       e23,  e31,  e12
        case ideal_line     //    e01,  e02,  e03
        case branch         //                           e23,  e31,  e12
        case motor          // s, e01,  e02,  e03,  i,   e23,  e31,  e12 (Dual Quaternion)
        case translator     // s, e01,  e02,  e03
        case rotor          // s,                        e23,  e31,  e12 (Quaternion)
        case complex        // s,                                    e12 (R01)

        // lorente algebra: SL(2, C)
        // complex quaternion
    }

    var type: GeoNumTypes
    var mv: Storage

    init(_ mv: Storage, _ type: GeoNumTypes) {
        self.mv = mv
        self.type = type
    }
}

extension R301 {
    static func join(a: Self, b: Self) -> Self {
        if a.type == .point && b.type == .point {
            return Self(a.mv, .line)
        } else {
            return a
        }
    }
}

extension R301 {
    static func plane(a: Scalar = 0, b: Scalar = 0, c: Scalar = 0, d: Scalar = 0) -> Self {
        Self(Storage(0, a, b, c, d, 0, 0, 0), .plane)
    }
    static func line(x: Scalar = 0, y: Scalar = 0, z: Scalar = 0, a: Scalar = 0, b: Scalar = 0, c: Scalar = 0) -> Self {
        if (a == 0 && b == 0 && c == 0) {
            return branch(x: x, y: y, z: z)
        } else if (x == 0 && y == 0 && z == 0) {
            return ideal_line(a: a, b: b, c: c)
        } else {
            return Self(Storage(0, a, b, c, 0, x, y, z), .line)
        }
    }
    static func ideal_line(a: Scalar = 0, b: Scalar = 0, c: Scalar = 0) -> Self {
        Self(Storage(0, a, b, c, 0, 0, 0, 0), .ideal_line)
    }
    static func branch(x: Scalar = 0, y: Scalar = 0, z: Scalar = 0) -> Self {
        Self(Storage(0, 0, 0, 0, 0, x, y, z), .branch)
    }
    static func point(x: Scalar = 0, y: Scalar = 0, z: Scalar = 0) -> Self {
        Self(Storage(0, x, y, z, 1, 0, 0, 0), .point)
    }
    static func direction(x: Scalar = 0, y: Scalar = 0, z: Scalar = 0) -> Self {
        Self(Storage(0, x, y, z, 0, 0, 0, 0), .direction)
    }
    static func motor(x: Scalar = 0, y: Scalar = 0, z: Scalar = 0, w: Scalar = 0, a: Scalar = 0, b: Scalar = 0, c: Scalar = 0, d: Scalar = 0) -> Self {
        Self(Storage(w, x, y, z, d, a, b, c), .motor)
    }
    static func translator(a: Scalar = 0, b: Scalar = 0, c: Scalar = 0, w: Scalar = 0) -> Self {
        Self(Storage(w, a, b, c, 0, 0, 0, 0), .translator)
    }
    static func translator(distance: Scalar, x: Scalar = 0, y: Scalar = 0, z: Scalar = 0) -> Self {
        let d = distance / 2
        return Self(Storage(1, x * d, y * d, z * d, 0, 0, 0, 0), .translator)
    }
    static func rotor(x: Scalar = 0, y: Scalar = 0, z: Scalar = 0, w: Scalar = 0) -> Self {
        Self(Storage(w, 0, 0, 0, 0, x, y, z), .rotor)
    }
    static func rotor(radians: Scalar, x: Scalar = 0, y: Scalar = 0, z: Scalar = 0) -> Self {
        let c = cos(radians / 2), s = sin(radians / 2)
        return Self(Storage(c, 0, 0, 0, 0, x * s, y * s, z * s), .rotor)
    }
    static func rotor(degrees: Scalar, x: Scalar = 0, y: Scalar = 0, z: Scalar = 0) -> Self {
        let c = cos(degrees / Scalar.pi / 2), s = sin(degrees / Scalar.pi / 2)
        return Self(Storage(c, 0, 0, 0, 0, x * s, y * s, z * s), .rotor)
    }
    static func hyperbolic(re: Scalar = 0, hy: Scalar = 0) -> Self {
        Self(Storage(re, hy, 0, 0, 0, 0, 0, 0), .hyperbolic)
    }
    static func complex(re: Scalar = 0, im: Scalar = 0) -> Self {
        Self(Storage(re, 0, 0, 0, 0, 0, 0, im), .complex)
    }
    static func dual(re: Scalar = 0, du: Scalar = 0) -> Self {
        Self(Storage(re, 0, 0, 0, du, 0, 0, 0), .dual)
    }
}

extension R301 {
    struct Polar {
        var norm: Scalar
        var angle: Scalar
        init(_ norm: Scalar, _ angle: Scalar) {
            self.norm = norm
            self.angle = angle
        }
        var eular: R301 { R301.complex(re: norm * cos(angle), im: norm * sin(angle)) }

        static func *(a: Self, b: Self) -> Self {
            Self(a.norm * b.norm, a.angle + b.angle)
        }
        static func *(a: Scalar, b: Self) -> Self {
            Self(a * b.norm, b.angle)
        }
        static func *(a: Self, b: Scalar) -> Self {
            Self(a.norm * b, a.angle)
        }
    }

    var polar: Polar {
        // complex:   s + e12
        // conjugate: s + e21
        Polar(s * s + e12 * e21, atan2(s, e12))
    }
}

extension R301 {
    var dual: Self {
        switch self.type {
        case .plane:
            if (e0 == 0) {
                return Self.direction(x: e1, y: e2, z: e3)
            } else {
                return Self.point(x: e1 / e0, y: e2 / e0, z: e3 / e0)
            }
        case .direction:
            return Self.plane(a: e023, b: e031, c: e012)
        case .point:
            return Self.plane(a: e023, b: e031, c: e012, d: e123)
        default:
            return self
        }
    }
}

extension R301 {
    var s: Scalar { mv[0] }

    var e0: Scalar { mv[4] }
    var e1: Scalar { mv[1] }
    var e2: Scalar { mv[2] }
    var e3: Scalar { mv[3] }

    var e01: Scalar {  mv[1] }
    var e10: Scalar { -mv[1] }
    var e02: Scalar {  mv[2] }
    var e20: Scalar { -mv[2] }
    var e03: Scalar {  mv[3] }
    var e30: Scalar { -mv[3] }
    var e12: Scalar {  mv[7] }
    var e21: Scalar { -mv[7] }
    var e31: Scalar {  mv[6] }
    var e13: Scalar { -mv[6] }
    var e23: Scalar {  mv[5] }
    var e32: Scalar { -mv[5] }

    var e021: Scalar {  mv[3] }
    var e012: Scalar { -mv[3] }
    var e102: Scalar {  mv[3] }
    var e120: Scalar { -mv[3] }
    var e210: Scalar {  mv[3] }
    var e201: Scalar { -mv[3] }
    var e013: Scalar {  mv[2] }
    var e031: Scalar { -mv[2] }
    var e301: Scalar {  mv[2] }
    var e310: Scalar { -mv[2] }
    var e130: Scalar {  mv[2] }
    var e103: Scalar { -mv[2] }
    var e032: Scalar {  mv[1] }
    var e023: Scalar { -mv[1] }
    var e203: Scalar {  mv[1] }
    var e230: Scalar { -mv[1] }
    var e320: Scalar {  mv[1] }
    var e302: Scalar { -mv[1] }
    var e123: Scalar {  mv[4] }
    var e132: Scalar { -mv[4] }
    var e231: Scalar { -mv[4] }
    var e213: Scalar {  mv[4] }
    var e312: Scalar {  mv[4] }
    var e321: Scalar { -mv[4] }

    var i: Scalar { mv[4] }
    var e0123: Scalar { mv[4] }
}

extension R301 {
    static func *(a: Scalar, b: Self) -> Self {
        switch b.type {
        default:
            return b
        }
    }

    static func *(a: Self, b: Scalar) -> Self {
        switch a.type {
        default:
            return a
        }
    }

    // geometric product
    static func *(a: Self, b: Self) -> Self {
        switch a.type {
        case .dual:
            switch b.type {
            case .dual:
                let du = a.s * b.e0 + a.e0 * b.s
                return Self(Storage(a.s * b.s, 0, 0, 0, du, 0, 0, 0), .dual)
            default:
                return a
            }
        default:
            return a
        }
    }
}

extension R301 {
}

