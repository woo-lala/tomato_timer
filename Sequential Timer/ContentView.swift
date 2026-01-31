//
//  ContentView.swift
//  Sequential Timer
//
//  Created by woolala on 1/17/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var languageStore: LanguageStore

    var body: some View {
        RoutineListView()
            .id(languageStore.selection)
    }
}

#Preview {
    ContentView()
}
