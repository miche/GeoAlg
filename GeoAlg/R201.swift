import Foundation
import simd
import SwiftUI

struct R201View: View {
    var body: some View {
        Text("R201")
    }
}

/// 2D PGA
struct R201 {
    typealias Scalar = Double
    typealias Storage = SIMD8<Scalar>

    enum GeoNumTypes {
        case hyperbolic     // s, e1                       (R1)
        case dual           // s,         e0,              (R001)
        case point          //               e02, e01, e12
        case direction      //               e02, e01

        case line           //    e1, e2, e0
        case motor          // s,            e02, e01, e12
        case translator     // s,            e02, e01
        case rotor          // s,            e02, e01, e12
        case complex        // s,                      e12 (R01)
    }

    struct GeoNum: Equatable, CustomStringConvertible {
        var mv: Storage

        var s: Scalar { mv[0] }
        var e1: Scalar { mv[1] }
        var e2: Scalar { mv[2] }
        var e0: Scalar { mv[3] }
        var e02: Scalar { -mv[4] }
        var e20: Scalar {  mv[4] }
        var e01: Scalar {  mv[5] }
        var e10: Scalar { -mv[5] }
        var e12: Scalar {  mv[6] }
        var e21: Scalar { -mv[6] }
        var e012: Scalar { mv[7] }
        var i: Scalar { mv[7] }

        var dual: Self { Self(Storage(mv[7], mv[6], mv[5], mv[4], mv[3], mv[2], mv[1], mv[0])) }
        var reverse: Self { Self(Storage(mv[0], mv[1], mv[2], mv[3], -mv[4], -mv[5], -mv[6], -mv[7])) }
        var involute: Self { Self(Storage(mv[0], -mv[1], -mv[2], -mv[3], mv[4], mv[5], mv[6], -mv[7])) }
        var conjugate: Self { Self(Storage(mv[0], -mv[1], -mv[2], -mv[3], -mv[4], -mv[5], -mv[6], mv[7])) }
        var inverse: Self {
            self.reverse.geoProd(self.involute).geoProd(self.conjugate).scale(1 / self.geoProd(self.conjugate).geoProd(self.involute).geoProd(self.reverse).s)
        }

        init(s: Scalar = 0, e1: Scalar = 0, e2: Scalar = 0, e0: Scalar = 0, e20: Scalar = 0, e01: Scalar = 0, e12: Scalar = 0, i: Scalar = 0) {
            mv = Storage(s, e1, e2, e0, e20, e01, e12, i)
        }
        init(_ es: Storage) {
            mv = es
        }
        var description: String {
            var es: [String] = []
            if (s   != 0) { es.append(String(s)) }
            if (e1  != 0) { es.append("\(e1)e1") }
            if (e2  != 0) { es.append("\(e2)e2") }
            if (e0  != 0) { es.append("\(e0)e0") }
            if (e20 != 0) { es.append("\(e20)e20") }
            if (e01 != 0) { es.append("\(e01)e01") }
            if (e12 != 0) { es.append("\(e12)e12") }
            if (i   != 0) { es.append("\(i)i") }
            if (es.count == 0) {
                return "0"
            } else {
                return es.joined(separator: " + ")
            }
        }
        func scale(_ s: Scalar) -> GeoNum {
            GeoNum(mv * s)
        }
        // <ab>
        func geoProd(_ other: GeoNum) -> GeoNum {
            let a = self, b = other
            return GeoNum(s:   a.s * b.s   + a.e1 * b.e1  + a.e2 * b.e2                                                 - a.e12 * b.e12,
                          e1:  a.s * b.e1  + a.e1 * b.s   - a.e2 * b.e12                                                + a.e12 * b.e2,
                          e2:  a.s * b.e2  + a.e1 * b.e12 + a.e2 * b.s                                                  - a.e12 * b.e1,
                          e0:  a.s * b.e0  - a.e1 * b.e01 + a.e2 * b.e20 + a.e0 * b.s   - a.e20 * b.e2  + a.e01 * b.e1  - a.e12 * b.i   - a.i * b.e12,
                          e20: a.s * b.e20 + a.e1 * b.i   + a.e2 * b.e0  - a.e0 * b.e2  + a.e20 * b.s   - a.e01 * b.e12 + a.e12 * b.e01 + a.i * b.e1,
                          e01: a.s * b.e01 - a.e1 * b.e0  + a.e2 * b.i   + a.e0 * b.e1  + a.e20 * b.e12 + a.e01 * b.s   - a.e12 * b.e20 + a.i * b.e2,
                          e12: a.s * b.e12 + a.e1 * b.e2  - a.e2 * b.e1                                                 + a.e12 * b.s,
                          i:   a.s * b.i   + a.e1 * b.e20 + a.e2 * b.e01 + a.e0 * b.e12 + a.e20 * b.e1  + a.e01 * b.e2  + a.e12 * b.e0  + a.i * b.s)
        }
        // <ab>_{s+t}
        func outerProd(_ other: GeoNum) -> GeoNum {
            let a = self, b = other
            return GeoNum(s:   a.s * b.s,
                          e1:  a.s * b.e1  + a.e1 * b.s,
                          e2:  a.s * b.e2                 + a.e2 * b.s,
                          e0:  a.s * b.e0                                + a.e0 * b.s,
                          e20: a.s * b.e20                + a.e2 * b.e0  - a.e0 * b.e2  + a.e20 * b.s,                               //  -a01 b.e12  a.e12 b.e01
                          e01: a.s * b.e01 - a.e1 * b.e0                 + a.e0 * b.e1                 + a.e01 * b.s,                //   a20 b.e12 -a.e12 b.e20
                          e12: a.s * b.e12 + a.e1 * b.e2  - a.e2 * b.e1                                               + a.e12 * b.s,
                          i:   a.s * b.i   + a.e1 * b.e20 + a.e2 * b.e01 + a.e0 * b.e12 + a.e20 * b.e1 + a.e01 * b.e2 + a.e12 * b.e0 + a.i * b.s)
        }
        // <ab>_{s-t}
        func innerProd(_ other: GeoNum) -> GeoNum {
            let a = self, b = other
            return GeoNum(s:   a.s * b.s   + a.e1 * b.e1  + a.e2 * b.e2                                             - a.e12 * b.e12,
                          e1:  a.s * b.e1  + a.e1 * b.s   - a.e2 * b.e12                                            + a.e12 * b.e2,
                          e2:  a.s * b.e2  + a.e1 * b.e12 + a.e2 * b.s                                              - a.e12 * b.e1,
                          e0:  a.s * b.e0  - a.e1 * b.e01 + a.e2 * b.e20 + a.e0 * b.s - a.e20 * b.e2 + a.e01 * b.e1 - a.e12 * b.i   - a.i * b.e12,
                          e20: a.s * b.e20 + a.e1 * b.i                               + a.e20 * b.s                                 + a.i * b.e1,
                          e01: a.s * b.e01                + a.e2 * b.i                               + a.e01 * b.s                  + a.i * b.e2,
                          e12: a.s * b.e12                                                                          + a.e12 * b.s,
                          i:   a.s * b.i                                                                                            + a.i * b.s)
        }
        // (a^* \wedge b^*)^*
        func regProd(_ other: GeoNum) -> GeoNum {
            let a = self, b = other
            return GeoNum(s:   a.s * b.i + a.e1 * b.e20 + a.e2 * b.e01 + a.e0 * b.e12 + a.e20 * b.e1  + a.e01 * b.e2  + a.e12 * b.e0  + a.i * b.s,
                          e1:              a.e1 * b.i                                                 - a.e01 * b.e12 + a.e12 * b.e01 + a.i * b.e1,
                          e2:                             a.e2 * b.i                  + a.e20 * b.e12                 - a.e12 * b.e20 + a.i * b.e2,
                          e0:                                            a.e0 * b.i   - a.e20 * b.e01 + a.e01 * b.e20                 + a.i * b.e0,
                          e20:                                                          a.e20 * b.i                                   + a.i * b.e20,
                          e01:                                                                          a.e01 * b.i                   + a.i * b.e01,
                          e12:                                                                                          a.e12 * b.i   + a.i * b.e12,
                          i:                                                                                                            a.i * b.i)
        }
        // <other self other.reverse>
        func sw(_ other: GeoNum) -> GeoNum {
            other.geoProd(self.geoProd(other.reverse))
        }
        //
        func exp() -> GeoNum {
            self
        }
    }

    struct Point: Shape {
        var mv: GeoNum

        init(e20: Scalar = 0, e01: Scalar = 0, e12: Scalar = 1) {
            mv = GeoNum(e20: e20, e01: e01, e12: e12)
        }
        init(_ e20: Scalar, _ e01: Scalar, _ e12: Scalar) {
            self.init(e20: e20, e01: e01, e12: e12)
        }
        init(_ x: Scalar, _ y: Scalar) {
            self.init(x, y, 1)
        }
        init(_ gn: GeoNum) {
            self.init(e20: gn.e20, e01: gn.e01, e12: gn.e12)
        }
        init(_ pt: CGPoint) {
            self.init(pt.x, pt.y)
        }
        var x: Scalar { mv.e20 / mv.e12 }
        var y: Scalar { mv.e01 / mv.e12 }
        var norm: Scalar { (self.mv.geoProd(self.mv.reverse)).s.squareRoot() }
        var cgpoint: CGPoint { CGPoint(x: x, y: y) }

        func translate(_ t: Translator) {
//            t * mv * t
        }
        func rotate(radians angle: Scalar) -> Point {
            Point(self.mv.sw(Rotor(radians: angle).mv))
        }
        func path(in rect: CGRect) -> Path {
            let r: CGFloat = 5
            return Path() { path in
                path.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            }
        }
        func join(_ other: Point) -> Line {
            Line(self.mv.regProd(other.mv))
        }
        func project(on line: Line) -> Point {
            Point((line.mv.innerProd(self.mv)).geoProd(line.mv))
        }
    }
    // Ideal Point
    struct Direction {
        var mv: GeoNum
        var normalized: Direction {
            let n2 = mv.e20 * mv.e20 + mv.e01 * mv.e01
            if (n2 != 0 && n2 != 1) {
                let n = n2.squareRoot()
                return Self(mv.e20 / n, mv.e01 / n)
            } else {
                return self
            }
        }
        init(e20: Scalar = 0, e01: Scalar = 0) {
            mv = GeoNum(e20: e20, e01: e01)
        }
        init(_ x: Scalar, _ y: Scalar) {
            self.init(e20: x, e01: y)
        }
        init(_ gn: GeoNum) {
            self.init(e20: gn.e20, e01: gn.e01)
        }
        var norm: Scalar { (mv.e20 * mv.e20 + mv.e01 * mv.e01).squareRoot() }
    }
    struct Line: Shape {
        var mv: GeoNum
        init(e1: Scalar = 0, e2: Scalar = 0, e0: Scalar = 0) {
            mv = GeoNum(e1: e1, e2: e2, e0: e0)
        }
        init(_ a: Scalar, _ b: Scalar, _ c: Scalar) {
            self.init(e1: a, e2: b, e0: c)
        }
        init(_ gn: GeoNum) {
            self.init(e1: gn.e1, e2: gn.e2, e0: gn.e0)
        }

        func path(in rect: CGRect) -> Path {
            let rectL = self.meet(Line(1, 0, -rect.minX))
            let rectR = self.meet(Line(1, 0, -rect.maxX))
            let rectT = self.meet(Line(0, 1, -rect.minY))
            let rectB = self.meet(Line(0, 1, -rect.maxY))
            let rangeX = rect.minX...rect.maxX
            let rangeY = rect.minY...rect.maxY
            var ps: [CGPoint] = []
            if rangeY.contains(rectL.y) { ps.append(rectL.cgpoint) }
            if rangeY.contains(rectR.y) { ps.append(rectR.cgpoint) }
            if rangeX.contains(rectT.x) { ps.append(rectT.cgpoint) }
            if rangeX.contains(rectB.x) { ps.append(rectB.cgpoint) }
            if ps.count == 2 {
                return Path { path in
                    path.move(to: ps[0])
                    path.addLine(to: ps[1])
                }
            } else {
                return Path()
            }
        }

        var norm: Scalar { (mv.e1 * mv.e1 + mv.e2 * mv.e2).squareRoot() }

        func meet(_ other: Line) -> Point {
            Point(self.mv.outerProd(other.mv))
        }
        func orthogonal(to other: Point) -> Line {
            Line(self.mv.innerProd(other.mv))
        }
        func project(on point: Point) -> Line {
            Line((self.mv.innerProd(point.mv)).geoProd(point.mv))
        }
        func othogonal() -> Direction {
            Direction(self.mv.geoProd(GeoNum(i: 1)))
        }
    }
    struct Rotor {
        var mv: GeoNum
        init(radians: Scalar, _ x: Scalar = 0, _ y: Scalar = 0) {
            let c = cos(radians / 2), s = sin(radians / 2)
            mv = GeoNum(s:c, e20: x * s, e01: y * s, e12: 1)
//            mv = GeoNum(e20: x * s, e01: y * s, e12: c)
        }
    }
    struct Translator {
        var mv: GeoNum
        init(dist: Scalar, _ x: Scalar, _ y: Scalar) {
            let d = dist / 2
            mv = GeoNum(s: 1, e20: x * d, e01: x * d)
        }
    }
    struct Motor {
        var mv: GeoNum
        init(dist: Scalar, _ x: Scalar, _ y: Scalar) {
            let d = dist / 2
            mv = GeoNum(s: 1, e20: x * d, e01: x * d)
        }
    }
}
