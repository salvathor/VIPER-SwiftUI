# VIPER-SwiftUI

Proyecto de ejemplo que muestra cómo implementar la arquitectura **VIPER** en una app de **SwiftUI**.

La app muestra una lista de productos, que se cargan de forma asíncrona, y permite navegar al detalle de cada uno.

## ¿Qué es VIPER?

VIPER divide cada pantalla (o *módulo*) en cinco capas, cada una con una sola responsabilidad:

| Capa | Rol | En este proyecto |
| --- | --- | --- |
| **V**iew | Muestra el estado y reenvía los eventos del usuario al Presenter. No tiene lógica de negocio. | `ProductListView`, `ProductDetailView` |
| **I**nteractor | Lógica de negocio y acceso a datos (API, BD…). No sabe nada de la UI. | `ProductInteractorProtocol`, `ProductInteractor` |
| **P**resenter | Pide datos al Interactor, los prepara y publica el estado que dibuja la View. | `ProductListPresenter` |
| **E**ntity | Modelos de datos simples. | `Product` |
| **R**outer | Ensambla los módulos (inyección de dependencias) y resuelve la navegación. | `ProductRouter` |

## Flujo de la app

```
App ──► ProductRouter.makeListProductView()
           │ crea Interactor + Presenter y los conecta con la View
           ▼
ProductListView ──onAppear──► ProductListPresenter ──fetch──► ProductInteractor
      ▲                               │                             │
      │      @Published products      │      [Product] (Entity)     │
      └───────────────────────────────┘◄────────────────────────────┘

Tap en una fila ──► navigationDestination ──► ProductRouter.makeDetailProductView()
                                                   ▼
                                            ProductDetailView
```

1. `VIPER_SwiftUIApp` le pide al **Router** el módulo de lista ya ensamblado.
2. Al aparecer, la **View** avisa al **Presenter** (`onAppear`).
3. El **Presenter** activa `isLoading` y le pide los productos al **Interactor** con `async/await`.
4. El **Interactor** devuelve un `[Product]` (**Entities**). Aquí simula una espera de 1 segundo.
5. El **Presenter** actualiza sus propiedades `@Published` y SwiftUI vuelve a dibujar la **View**.
6. Al tocar un producto, `NavigationLink(value:)` emite el `Product` y `navigationDestination` le pide al **Router** la vista de detalle.

## Estructura

```
VIPER-SwiftUI/
├── VIPER_SwiftUIApp.swift   // Punto de entrada: usa el Router para crear el primer módulo
├── ContentView.swift        // Entity, Interactor, Presenter, Router y Views del módulo Productos
└── Assets.xcassets
```

> Por simplicidad didáctica, todas las capas están en `ContentView.swift`, separadas con `// MARK:`. En un proyecto real cada capa suele ir en su propio archivo, y cada módulo en su propia carpeta.

## Conceptos clave

- **Inyección de dependencias por protocolo:** el Presenter depende de `ProductInteractorProtocol`, no de una implementación concreta. Así es fácil sustituirla por un *mock* en las pruebas.
- **`@MainActor` en el Presenter:** garantiza que el estado de la UI se actualice en el hilo principal.
- **`@StateObject` en la View:** conserva la misma instancia del Presenter aunque `body` se recalcule.
- **Navegación por valor:** `Product` cumple con `Hashable` para usar `NavigationLink(value:)` y `navigationDestination(for:)`.

> ⚠️ **Importante:** `.navigationDestination` y `.navigationTitle` deben ir **dentro** del `NavigationStack`. Si se aplican por fuera, el stack no los detecta y la navegación al detalle no funciona.

## Requisitos

- Xcode con un SDK de iOS compatible con `NavigationStack` (iOS 16 o posterior).
- Swift Concurrency (`async/await`).

## Cómo ejecutar

1. Abre `VIPER-SwiftUI.xcodeproj` en Xcode.
2. Selecciona un simulador o dispositivo.
3. Ejecuta con **⌘R**.
