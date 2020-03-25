import SwiftUI
import libIdbcl

private let allColors: [Color] = [Color.orange, Color.blue, Color.green, Color.purple, Color.primary, Color.pink].shuffled()
private func getColor(_ i: Int) -> Color { allColors[Int(i.magnitude) % allColors.count] }

struct RootView: View {
    let reporter: Reporter
    
    @State var fun = PlotData()

    var body: some View {
        NavigationView {
            LeftView(reporter: reporter)
            RightView()
        }.environmentObject(fun)
    }
}


struct LeftView: View {
    let reporter: Reporter
    
    var lists: [PlayList] {
        let all = reporter.playlists(groupBy: groups).sorted(by: { $0.name < $1.name })
        return filter != "" ? all.filter { $0.name.contains(filter) } : all
    }
    
    @State var filter: String = ""
    @State var groups: [String] = ["Artist"]
    @EnvironmentObject var fun: PlotData
    
    var body: some View {
        
        return VStack {
            DomainSelector()
                .padding([.horizontal, .top], 5)
            FunctionSelector()
                .padding([.horizontal], 5)
            GroupSelectorView(groups: self.$groups)
                .padding([.horizontal], 5)
            
            List(lists, id: \.self, selection: self.$fun.cursor) { list in
                RowView(list: list)
            }
            .listStyle(SidebarListStyle())
            .id((groups + [filter]).self)
            
            TextField("Filter", text: $filter)
        }
    }
}


struct DomainSelector: View {
    @EnvironmentObject var fun: PlotData
    
    let domainMatrix = [["1D", "1W", "1M", "3M"], ["6M", "1Y", "2Y", "5Y"]]
    
    var body: some View {
        VStack{
            ForEach(domainMatrix, id: \.self) { domains in
                HStack {
                    ForEach(domains, id: \.self) { domain in
                        Button(action: { self.fun.domain = domain }) {
                            Text(domain)
                                .foregroundColor(domain == self.fun.domain ? Color.accentColor : Color.primary)
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}


struct GroupSelectorView: View {
    @Binding var groups: [String]
    
    func addGroup(str: String) { if validGroups.contains(str) { groups.append(str) }}
    
    var body: some View {
        HStack {
            ForEach(groups, id: \.self) { group in
                Button(action: {
                    self.groups.removeAll(where: { $0 == group })
                }) {
                    Text(group + " ×")
                }
            }
            MenuButton("＋") {
                ForEach(validGroups, id: \.self) { grp in
                    Button(grp) { self.addGroup(str: grp) }
                }
            }
            .menuButtonStyle(PullDownMenuButtonStyle())
            .fixedSize()
            Spacer()
        }
    }
}

struct FunctionSelector: View {
    @EnvironmentObject var fun: PlotData
    
    let options = ["PlayCount", "Rating"]
    
    var body: some View {
        HStack {
            Picker(selection: self.$fun.function, label: EmptyView()) {
                ForEach(options, id: \.description) { fun in
                    Text(fun.description).tag(fun)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .fixedSize()
            Spacer()
        }
    }
}


struct RowView: View {
    var list: PlayList
    
    var body: some View {
        HStack {
            Text(list.name)
            Spacer()
            Text("\(list.tracks.count) IDs")
                .foregroundColor(Color.secondary)
        }
    }
}


struct RightView: View {
    @EnvironmentObject var fun: PlotData
    
    var showCursorButton: Bool { fun.cursor != nil && !fun.selection.contains(fun.cursor!) }
    
    var body: some View {
        VStack {
            MultiLinePlot()
            HStack {
                
                ForEach(fun.selection.indices, id: \.self) { n in Button(action: {
                    self.fun.selection = self.fun.selection.filter({ $0 != self.fun.selection[n] })
                }) {
                    Text(self.fun.selection[n].name + " ×")
                        .foregroundColor(getColor(n))
                }}
                
                if showCursorButton {
                    Button(fun.cursor!.name + " ＋") {
                        self.fun.selection = self.fun.selection + [self.fun.cursor!]
                    }.foregroundColor(getColor(fun.selection.count))
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(5)
    }
}

extension Double {
    var orderOfMagnitude: Double {
        let log = log10(self.magnitude)
        return log >= 0 ? log.rounded(.down) : -((1/self).orderOfMagnitude + 1)
    }
}

struct MultiLinePlot: View {
    @EnvironmentObject var params: PlotData
    
    func ruler(_ reader: GeometryProxy) -> some View {
        let delta = params.yRange.upperBound - params.yRange.lowerBound
        let magnitude = delta.orderOfMagnitude
        let y = Double(reader.size.height)/delta * pow(10.0, magnitude)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: y))
        return ZStack {
            path
                .stroke(lineWidth: 2)
            Text(String(describing: pow(10.0, magnitude)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: 0, y: CGFloat(y))
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.secondary, lineWidth: 1.0)
            if !params.yRange.isEmpty {
                GeometryReader { self.ruler($0) }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            ForEach(self.params.data.indices, id: \.self) { n in
                LinePlot(data: self.params.data[n], color: getColor(n)) }
        }
    }
}


struct LinePlot: View {
    var data: AnimatableData
    let color: Color
    
    @State var hasAppeared: Bool = false
    
    var body: some View {
        Graph(data: data)
            .trim(from: 0, to: hasAppeared ? 1 : 0)
            .stroke(color, lineWidth: 3.0)
            .animation(.interpolatingSpring(mass: 0.01, stiffness: 1, damping: 0.1, initialVelocity: 0))
            .onAppear { self.hasAppeared.toggle() }
    }
}


struct Graph: Shape {
    var data: AnimatableData
    
    var animatableData: AnimatableData {
        get { data }
        set { self.data = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let xscale = Double(rect.maxX)/Double(data.values.count - 1)
        
        path.move(to: CGPoint(x: 0, y: Double(rect.maxY) * (1 - data.values[0])))
        path.addLines(data.values.enumerated().map { (index, y) in
            let y = Double(rect.maxY) * (1 - y)
            let x = Double(index) * xscale
            return CGPoint(x: x, y: y)})
        
        return path
    }
}
