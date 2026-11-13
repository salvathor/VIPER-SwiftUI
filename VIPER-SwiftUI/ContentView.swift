//
//  ContentView.swift
//  VIPER-SwiftUI
//
//  Created by Salvador Lopez on 13/11/26.
//

// ============================================================================
//  ARQUITECTURA VIPER
// ============================================================================
//  VIPER divide cada pantalla (o "módulo") en 5 responsabilidades:
//
//   V - View       → Muestra datos y reenvía eventos del usuario al Presenter.
//                    No contiene lógica de negocio.
//   I - Interactor → Lógica de negocio y acceso a datos (API, BD, etc.).
//                    No sabe nada de la UI.
//   P - Presenter  → Intermediario: pide datos al Interactor, los prepara y
//                    expone el estado que la View dibuja.
//   E - Entity     → Modelos de datos simples (structs) que usa el Interactor.
//   R - Router     → Construye los módulos (inyecta dependencias) y decide
//                    la navegación entre pantallas.
//
//  Flujo en este proyecto:
//
//   App ──► Router.makeListProductView()
//              │ crea Interactor + Presenter y los conecta con la View
//              ▼
//   ProductListView ──onAppear──► ProductListPresenter ──fetch──► ProductInteractor
//         ▲                               │                             │
//         │      @Published products      │      [Product] (Entity)     │
//         └───────────────────────────────┘◄────────────────────────────┘
//
//   Tap en una fila ──► navigationDestination ──► Router.makeDetailProductView()
//                                                      ▼
//                                               ProductDetailView
// ============================================================================

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
// Modelo de datos puro: sin lógica ni dependencias de UI.
// - Identifiable: permite usarlo directamente en `List`.
// - Hashable: necesario para `NavigationLink(value:)` y
//   `navigationDestination(for:)`, que identifican el destino por valor.
struct Product: Identifiable, Hashable{
    let id: Int
    let name: String
    let price: Double
}

//MARK: INTERACTOR (I)
// El protocolo define QUÉ puede hacer el Interactor, no CÓMO.
// El Presenter depende de esta abstracción, lo que permite sustituir la
// implementación (p. ej. un mock en tests o un servicio de red real)
// sin tocar el Presenter.
protocol ProductInteractorProtocol {
    func fetchProducts() async -> [Product]
}

// Implementación concreta: aquí vive la lógica de negocio / obtención de datos.
// En una app real haría una petición HTTP o consultaría una base de datos;
// aquí simula una espera de 1 segundo y devuelve datos fijos.
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
// Mantiene el estado de la pantalla y coordina View ↔ Interactor.
// - @MainActor: todo el estado se actualiza en el hilo principal (UI).
// - ObservableObject + @Published: cuando cambian `products` o `isLoading`,
//   SwiftUI vuelve a dibujar la View automáticamente.
// - private(set): solo el Presenter modifica el estado; la View solo lo lee.
@MainActor
final class ProductListPresenter: ObservableObject {

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false

    // Dependencia inyectada por el Router a través del protocolo.
    private let interactor: any ProductInteractorProtocol

    init(interactor: any ProductInteractorProtocol){
        self.interactor = interactor
    }

    // Evento que la View reenvía al aparecer. La View no decide cuándo
    // cargar datos; esa decisión es del Presenter.
    func onAppear(){
        // Evita recargar si ya hay datos (p. ej. al regresar del detalle).
        guard products.isEmpty else {
            return
        }
        isLoading = true
        // Pide los datos al Interactor de forma asíncrona y actualiza el
        // estado publicado, lo que provoca que la View se redibuje.
        Task{
            products = await interactor.fetchProducts()
            isLoading = false
        }
    }

}

//MARK: ROUTER (R)
// Punto de ensamblaje de los módulos y de la navegación.
// Es el único lugar que conoce las implementaciones concretas
// (ProductInteractor, ProductListPresenter, vistas); el resto de capas
// solo se comunican mediante abstracciones o datos.
@MainActor
enum ProductRouter {
    // Crea Modulo para la vista de productos
    // Arma el módulo completo: Interactor → Presenter → View.
    static func makeListProductView() -> some View {
        let presenter = ProductListPresenter(interactor: ProductInteractor())
        return ProductListView(presenter: presenter)
    }
    // Crea Modulo para la vista detalle
    // La View de lista no crea el detalle directamente: se lo pide al Router.
    static func makeDetailProductView(_ product:Product) -> some View {
        ProductDetailView(product: product)
    }
}

//MARK: VIEWs (V)

// Vista "pasiva": solo dibuja el estado del Presenter y le reenvía eventos.
struct ProductListView: View {

    // @StateObject hace que SwiftUI conserve el mismo Presenter durante
    // toda la vida de la vista, aunque `body` se recalcule muchas veces.
    @StateObject private var presenter: ProductListPresenter

    // El Presenter llega inyectado desde el Router (no se crea aquí).
    init(presenter: ProductListPresenter) {
        _presenter = StateObject(wrappedValue: presenter)
    }

    var body: some View {
        NavigationStack {
            // El contenido depende únicamente del estado del Presenter.
            Group{
                    if presenter.isLoading {
                        ProgressView("Cargando productos...")
                    } else {
                        List(presenter.products){ product in
                            // Navegación por valor: el link solo "emite" el
                            // Product; quien decide qué pantalla mostrar es
                            // `navigationDestination` (y en última instancia el Router).
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
            // Estos modificadores deben ir DENTRO del NavigationStack para
            // que el stack los detecte; si se colocan fuera, la navegación
            // al detalle no funciona.
            .navigationTitle("Productos")
            .navigationDestination(for: Product.self) { product in
                // Se delega la construcción del destino al Router.
                ProductRouter.makeDetailProductView(product)
            }
        }
        // La View no carga datos: solo notifica el evento al Presenter.
        .onAppear{
            presenter.onAppear()
        }

    }

}

// Módulo de detalle sencillo: recibe la Entity ya resuelta y solo la muestra,
// por eso no necesita Presenter ni Interactor propios. Si tuviera lógica
// (p. ej. cargar más información o "agregar al carrito"), se le añadirían.
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
