//
//  ContentView.swift
//  VIPER-SwiftUI
//
//  Created by Salvador Lopez on 13/11/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

// MARK: ENTIDAD (E)
struct Product: Identifiable, Hashable{
    let id: Int
    let name: String
    let price: Double
}

//MARK: INTERACTOR (I)
protocol ProductInteractorProtocol {
    func fetchProducts() async -> [Product]
}

struct ProductInteractor: ProductInteractorProtocol {
    func fetchProducts() async -> [Product] {
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simular time
        return [
            Product(id: 1, name: "Café", price: 45),
            Product(id: 2, name: "Pan", price: 22),
            Product(id: 3, name: "Leche", price: 30)
        ]
    }
}

//MARK: PRESENTER (P)
@MainActor
final class ProductListPresenter: ObservableObject {
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    
    private let interactor: any ProductInteractorProtocol
    
    init(interactor: any ProductInteractorProtocol){
        self.interactor = interactor
    }
    
    func onAppear(){
        guard products.isEmpty else {
            return
        }
        isLoading = true
        Task{
            products = await interactor.fetchProducts()
            isLoading = false
        }
    }
    
}

//MARK: ROUTER (R)
@MainActor
enum ProductRouter {
    // Crea Modulo para la vista de productos
    static func makeListProductView() -> some View {
        let presenter = ProductListPresenter(interactor: ProductInteractor())
        return ProductListView(presenter: presenter)
    }
    // Crea Modulo para la vista detalle
    static func makeDetailProductView(_ product:Product) -> some View {
        ProductDetailView(product: product)
    }
}

//MARK: VIEWs (V)

struct ProductListView: View {
    
    @StateObject private var presenter: ProductListPresenter
    
    init(presenter: ProductListPresenter) {
        _presenter = StateObject(wrappedValue: presenter)
    }
    
    var body: some View {
        NavigationStack {
            Group{
                    if presenter.isLoading {
                        ProgressView("Cargando productos...")
                    } else {
                        List(presenter.products){ product in
                            NavigationLink(value:product){
                                HStack {
                                    Text(product.name)
                                    Spacer()
                                    Text(product.price, format: .currency(code: "MXN"))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            .navigationTitle("Productos")
            .navigationDestination(for: Product.self) { product in
                ProductRouter.makeDetailProductView(product)
            }
        }
        .onAppear{
            presenter.onAppear()
        }
        
    }
    
}

struct ProductDetailView : View {
    
    let product: Product
    
    var body: some View{
        VStack(spacing: 16){
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            Text(product.name)
                .font(.title.bold())
            Text(product.price, format: .currency(code: "MXN"))
                .font(.title3)
        }
        .navigationTitle("Detalle producto")
    }
    
}
