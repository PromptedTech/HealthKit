import WidgetKit
import SwiftUI

@main
struct AbsCountdownWidgetBundle: WidgetBundle {
    var body: some Widget {
        AbsCountdownWidget()
        AbsLiveActivityWidget()
    }
}
