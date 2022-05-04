import SwiftUI

struct GridView: View {
    var body: some View {
        Path() { path in
            stride(from: 100, to: 600, by: 100).forEach { n in
                path.move(to: CGPoint(x: 0, y: n))
                path.addLine(to: CGPoint(x: 1000, y: n))
                path.move(to: CGPoint(x: n, y: 0))
                path.addLine(to: CGPoint(x: n, y: 1000))
            }
        }.stroke(lineWidth: 1)
    }
}
struct ContentView: View {
    @State var a = R201.Point(20, 20)
    @State var b = R201.Point(150, 80)
    @State var c = R201.Point(30, 180)
    var o = R201.Point(300, 200)
    var body: some View {
        ZStack {
            GridView()
            o
            Text("b").position(x: b.x, y: b.y + 15)
            o.join(b).stroke(lineWidth: 3).foregroundColor(.red)
            b.gesture(DragGesture().onChanged({ val in
                b = R201.Point(val.location)
            }))
            a
            o.project(on: a.join(b))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
