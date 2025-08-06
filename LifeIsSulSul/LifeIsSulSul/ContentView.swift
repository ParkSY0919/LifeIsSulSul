//
//  ContentView.swift
//  LifeIsSulSul
//
//  Created by 박신영 on 8/5/25.
//  
//  이 파일은 TCA 전환 후 제거됩니다.
//  현재는 테스트용으로만 유지됩니다.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "wineglass.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("TCA 전환 완료!")
                .font(.headline)
            Text("앱을 실행하면 SplashView → OnboardingView → DrinkTrackingView 순으로 진행됩니다.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
