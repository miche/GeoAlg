import XCTest
@testable import GeoAlg

class GeoAlgTests: XCTestCase {
    func test() {
        let p = R301.point(x: 2, y: 3, z: 4)
        XCTAssertEqual(p.e032, 2)
        XCTAssertEqual(p.e013, 3)
        XCTAssertEqual(p.e021, 4)
        XCTAssertEqual(p.e123, 1)
        let d = R301.direction(x: 2, y: 3, z: 4)
        XCTAssertEqual(d.e032, 2)
        XCTAssertEqual(d.e013, 3)
        XCTAssertEqual(d.e021, 4)
        XCTAssertEqual(d.e123, 0)
        let pl = R301.plane(a: 1, b: 2, c: 3, d: 4)
        XCTAssertEqual(pl.e1, 1)
        XCTAssertEqual(pl.e2, 2)
        XCTAssertEqual(pl.e3, 3)
        XCTAssertEqual(pl.e0, 4)

        let angle = Double.pi / 2
        let r = R301.rotor(radians: angle, x: 1, y: 2, z: 3)
        XCTAssertEqual(r.s, cos(angle / 2))
        XCTAssertEqual(r.e23, sin(angle / 2) * 1)
        XCTAssertEqual(r.e31, sin(angle / 2) * 2)
        XCTAssertEqual(r.e12, sin(angle / 2) * 3)
        let t = R301.translator(distance: 1, x: 2, y: 3, z: 4)
        XCTAssertEqual(t.s, 1)
        let dst = Double(1) / 2
        XCTAssertEqual(t.e01, 2 * dst)
        XCTAssertEqual(t.e02, 3 * dst)
        XCTAssertEqual(t.e03, 4 * dst)
    }

    func test_geo() {
        let a = R201.GeoNum(s: 11, e1: 12, e2: 13, e0: 14, e20: 15, e01: 16, e12: 17, i: 18)
        let b = R201.GeoNum(s: 1, e1: 2, e2: 3, e0: 4, e20: 5, e01: 6, e12: 7, i: 8)
        XCTAssertEqual(R201.GeoNum(s: 1).geoProd(b), b)
        XCTAssertEqual(R201.GeoNum(e1: 1).geoProd(b), R201.GeoNum(s: 2, e1: 1, e2: 7, e0: -6, e20: 8, e01: -4, e12: 3, i: 5))
        XCTAssertEqual(R201.GeoNum(e2: 1).geoProd(b), R201.GeoNum(s: 3, e1: -7, e2: 1, e0: 5, e20: 4, e01: 8, e12: -2, i: 6))
        XCTAssertEqual(R201.GeoNum(e0: 1).geoProd(b), R201.GeoNum(e0: 1, e20: -3, e01: 2, i: 7))
        XCTAssertEqual(R201.GeoNum(e20: 1).geoProd(b), R201.GeoNum(e0: -3, e20: 1, e01: 7, i: 2))
        XCTAssertEqual(R201.GeoNum(e01: 1).geoProd(b), R201.GeoNum(e0: 2, e20: -7, e01: 1, i: 3))
        XCTAssertEqual(R201.GeoNum(e12: 1).geoProd(b), R201.GeoNum(s: -7, e1: 3, e2: -2, e0: -8, e20: 6, e01: -5, e12: 1, i: 4))
        XCTAssertEqual(R201.GeoNum(i: 1).geoProd(b), R201.GeoNum(e0: -7, e20: 2, e01: 3, i: 1))
        XCTAssertEqual(a.geoProd(b), R201.GeoNum(s: -45, e1: -6, e2: 96, e0: -224, e20: 202, e01: 240, e12: 104, i: 488))
    }
    func test_wedge() {
        let a = R201.GeoNum(s: 11, e1: 12, e2: 13, e0: 14, e20: 15, e01: 16, e12: 17, i: 18)
        let b = R201.GeoNum(s: 1, e1: 2, e2: 3, e0: 4, e20: 5, e01: 6, e12: 7, i: 8)
        XCTAssertEqual(R201.GeoNum(s: 1).outerProd(b), b)
        XCTAssertEqual(R201.GeoNum(e1: 1).outerProd(b), R201.GeoNum(e1: 1, e01: -4, e12: 3, i: 5))
        XCTAssertEqual(R201.GeoNum(e2: 1).outerProd(b), R201.GeoNum(e2: 1, e20: 4, e12: -2, i: 6))
        XCTAssertEqual(R201.GeoNum(e0: 1).outerProd(b), R201.GeoNum(e0: 1, e20: -3, e01: 2, i: 7))
        XCTAssertEqual(R201.GeoNum(e20: 1).outerProd(b), R201.GeoNum(e20: 1, i: 2))
        XCTAssertEqual(R201.GeoNum(e01: 1).outerProd(b), R201.GeoNum(e01: 1, i: 3))
        XCTAssertEqual(R201.GeoNum(e12: 1).outerProd(b), R201.GeoNum(e12: 1, i: 4))
        XCTAssertEqual(R201.GeoNum(i: 1).outerProd(b), R201.GeoNum(i: 1))
        XCTAssertEqual(a.outerProd(b), R201.GeoNum(s: 11, e1: 34, e2: 46, e0: 58, e20: 80, e01: 62, e12: 104, i: 488))
    }
//(11.0 + 12.0e1 + 13.0e2 + 14.0e0 +15.0e20 + 16.0e01 + 17.0e12 + 18.0e012)|(1.0 + 2.0e1 + 3.0e2 + 4.0e0 + 5.0e20 + 6.0e01 + 7.0e12 + 8.0e012)
    func test_dot() {
        let a = R201.GeoNum(s: 11, e1: 12, e2: 13, e0: 14, e20: 15, e01: 16, e12: 17, i: 18)
        let b = R201.GeoNum(s: 1, e1: 2, e2: 3, e0: 4, e20: 5, e01: 6, e12: 7, i: 8)
        XCTAssertEqual(R201.GeoNum(s: 1).innerProd(b), b)
        XCTAssertEqual(R201.GeoNum(e1: 1).innerProd(b), R201.GeoNum(s: 2, e1: 1, e2: 7, e0: -6, e20: 8))
        XCTAssertEqual(R201.GeoNum(e2: 1).innerProd(b), R201.GeoNum(s: 3, e1: -7, e2: 1, e0: 5, e01: 8))
        XCTAssertEqual(R201.GeoNum(e0: 1).innerProd(b), R201.GeoNum(e0: 1))
        XCTAssertEqual(R201.GeoNum(e20: 1).innerProd(b), R201.GeoNum(e0: -3, e20: 1))
        XCTAssertEqual(R201.GeoNum(e01: 1).innerProd(b), R201.GeoNum(e0: 2, e01: 1))
        XCTAssertEqual(R201.GeoNum(e12: 1).innerProd(b), R201.GeoNum(s: -7, e1: 3, e2: -2, e0: -8, e12: 1))
        XCTAssertEqual(R201.GeoNum(i: 1).innerProd(b), R201.GeoNum(e0: -7, e20: 2, e01: 3, i: 1))
        XCTAssertEqual(a.innerProd(b), R201.GeoNum(s: -45, e1: -6, e2: 96, e0: -224, e20: 202, e01: 240, e12: 94, i: 106))
    }
    func test_reg() {
        //(11.0 + 12.0e1 + 13.0e2 + 14.0e0 +15.0e20 + 16.0e01 + 17.0e12 + 18.0e012)&(1.0 + 2.0e1 + 3.0e2 + 4.0e0 + 5.0e20 + 6.0e01 + 7.0e12 + 8.0e012)
        let a = R201.GeoNum(s: 11, e1: 12, e2: 13, e0: 14, e20: 15, e01: 16, e12: 17, i: 18)
        let b = R201.GeoNum(s: 1, e1: 2, e2: 3, e0: 4, e20: 5, e01: 6, e12: 7, i: 8)
        XCTAssertEqual(R201.GeoNum(s: 1).regProd(b), R201.GeoNum(s: 8))
        XCTAssertEqual(R201.GeoNum(e1: 1).regProd(b), R201.GeoNum(s: 5, e1: 8))
        XCTAssertEqual(R201.GeoNum(e2: 1).regProd(b), R201.GeoNum(s: 6, e2: 8))
        XCTAssertEqual(R201.GeoNum(e0: 1).regProd(b), R201.GeoNum(s: 7, e0: 8))
        XCTAssertEqual(R201.GeoNum(e20: 1).regProd(b), R201.GeoNum(s: 2, e2: 7, e0: -6, e20: 8))
        XCTAssertEqual(R201.GeoNum(e01: 1).regProd(b), R201.GeoNum(s: 3, e1: -7, e0: 5, e01: 8))
        XCTAssertEqual(R201.GeoNum(e12: 1).regProd(b), R201.GeoNum(s: 4, e1: 6, e2: -5, e12: 8))
        XCTAssertEqual(R201.GeoNum(i: 1).regProd(b), R201.GeoNum(s: 1, e1: 2, e2: 3, e0: 4, e20: 5, e01: 6, e12:7, i: 8))
        XCTAssertEqual(a.regProd(b), R201.GeoNum(s: 488, e1: 122, e2: 178, e0: 174, e20: 210, e01: 236, e12: 262, i: 144))
    }
    func test_sw() {
        // (11.0 + 12.0e1 + 13.0e2 + 14.0e0 +15.0e20 + 16.0e01 + 17.0e12 + 18.0e012) >>> (1.0 + 2.0e1 + 3.0e2 + 4.0e0 + 5.0e20 + 6.0e01 + 7.0e12 + 8.0e012)
        let a = R201.GeoNum(s: 11, e1: 12, e2: 13, e0: 14, e20: 15, e01: 16, e12: 17, i: 18)
        let b = R201.GeoNum(s: 1, e1: 2, e2: 3, e0: 4, e20: 5, e01: 6, e12: 7, i: 8)
        XCTAssertEqual(b.sw(R201.GeoNum(s: 1)), b)
        XCTAssertEqual(b.sw(R201.GeoNum(e1: 1)), R201.GeoNum(s: 1, e1: 2, e2: -3, e0: -4, e20: 5, e01: -6, e12: -7, i: 8))
        XCTAssertEqual(b.sw(R201.GeoNum(e2: 1)), R201.GeoNum(s: 1, e1: -2, e2: 3, e0: -4, e20: -5, e01: 6, e12: -7, i: 8))
        XCTAssertEqual(b.sw(R201.GeoNum(e0: 1)), R201.GeoNum(s: 0))
        XCTAssertEqual(b.sw(R201.GeoNum(e20: 1)), R201.GeoNum(s: 0))
        XCTAssertEqual(b.sw(R201.GeoNum(e01: 1)), R201.GeoNum(s: 0))
        XCTAssertEqual(b.sw(R201.GeoNum(e12: 1)), R201.GeoNum(s: 1, e1: -2, e2: -3, e0: 4, e20: -5, e01: -6, e12: 7, i: 8))
        XCTAssertEqual(b.sw(R201.GeoNum(i: 1)), R201.GeoNum(s: 0))
        XCTAssertEqual(b.sw(a), R201.GeoNum(s: 2449, e1: 2378, e2: -675, e0: 5792, e20: 15533, e01: 3498, e12: 679, i: 15540))
//        XCTAssertEqual(b.sw(R201.GeoNum(e1: a.s)), R201.GeoNum(s: 121, e1: 242, e2: -363, e0: -484, e20: 605, e01: 726, e12: 847, i: 968))
//        XCTAssertEqual(b.sw(R201.GeoNum(e1: a.e1)), R201.GeoNum(s: 1, e1: 2, e2: -3, e0: -4, e20: 5, e01: -6, e12: -7, i: 8))
//        XCTAssertEqual(b.sw(R201.GeoNum(e2: a.e2)), R201.GeoNum(s: 1, e1: -2, e2: 3, e0: -4, e20: -5, e01: 6, e12: -7, i: 8))
//        XCTAssertEqual(b.sw(R201.GeoNum(e12: a.e12)), R201.GeoNum(s: 1, e1: -2, e2: -3, e0: 4, e20: -5, e01: -6, e12: 7, i: 8))
    }
}
