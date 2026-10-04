# Kotlin Multiplatform (KMP) Auto-Generated Localization Guide

This guide provides a comprehensive step-by-step overview of using **JetBrains Compose Multiplatform Resources** (`components.resources`), the official native mechanism in KMP for auto-generating type-safe localization resources directly from `strings.xml` files—similar to how Flutter auto-generates string accessors from `.arb` files.

---

## Overview: Flutter (`.arb`) vs. KMP (`strings.xml`)

| Feature | Flutter Native (`flutter gen-l10n`) | KMP Native (`components.resources`) |
| :--- | :--- | :--- |
| **Resource File Format** | `.arb` (JSON format) | `strings.xml` (Android Android-style XML) |
| **File Location** | `lib/l10n/app_en.arb` | `commonMain/composeResources/values/strings.xml` |
| **Code Generation Tool** | `flutter_localizations` / `gen-l10n` | Compose Multiplatform Gradle Plugin (`Res`) |
| **Generated Class** | `AppLocalizations` | `Res` (`Res.string.*`) |
| **Composable / UI Usage** | `AppLocalizations.of(context)!.hello` | `stringResource(Res.string.hello)` |
| **Non-UI / Async Usage** | `AppLocalizations.delegate` | `getString(Res.string.hello)` |

---

## 1. Gradle Configuration

Enable the `components.resources` plugin in your KMP module's `build.gradle.kts`:

```kotlin
plugins {
    kotlin("multiplatform")
    id("org.jetbrains.compose")
    id("org.jetbrains.kotlin.plugin.compose")
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            // Compose Multiplatform UI foundation
            implementation(compose.runtime)
            implementation(compose.foundation)
            implementation(compose.material3)

            // Official JetBrains Multiplatform Resources dependency
            implementation(compose.components.resources)
        }
    }
}

// Optional: Custom package name configuration for generated Res class
compose.resources {
    publicResClass = true
    packageOfResClass = "com.yourpackage.app.generated.resources"
}
```

---

## 2. Directory Structure

Place your `strings.xml` resource files inside `commonMain/composeResources/`:

```
your-kmp-project/
├── composeApp/ (or shared/)
│   └── src/
│       └── commonMain/
│           ├── composeResources/
│           │   ├── values/               <-- Default / English strings
│           │   │   └── strings.xml
│           │   ├── values-es/            <-- Spanish translations
│           │   │   └── strings.xml
│           │   ├── values-ar/            <-- Arabic translations
│           │   │   └── strings.xml
│           │   └── values-fr/            <-- French translations
│           │       └── strings.xml
│           └── kotlin/
│               └── com/yourpackage/app/
│                   └── App.kt
```

---

## 3. Defining XML Strings

### Default Strings (`commonMain/composeResources/values/strings.xml`)

```xml
<resources>
    <!-- Simple String -->
    <string name="app_name">My KMP App</string>
    <string name="welcome_message">Welcome back to our store!</string>
    <string name="action_checkout">Proceed to Checkout</string>

    <!-- Strings with Formatted Parameters -->
    <string name="greeting_user">Hello, %1$s!</string>
    <string name="item_count">You have %1$d items in your cart totaling %2$s.</string>

    <!-- Quantity / Plurals -->
    <plurals name="cart_items">
        <item quantity="zero">Your cart is empty</item>
        <item quantity="one">You have 1 item in your cart</item>
        <item quantity="other">You have %d items in your cart</item>
    </plurals>

    <!-- String Arrays -->
    <string-array name="category_list">
        <item>Electronics</item>
        <item>Clothing</item>
        <item>Books</item>
    </string-array>
</resources>
```

### Spanish Translations (`commonMain/composeResources/values-es/strings.xml`)

```xml
<resources>
    <string name="app_name">Mi Aplicación KMP</string>
    <string name="welcome_message">¡Bienvenido de nuevo a nuestra tienda!</string>
    <string name="action_checkout">Proceder al pago</string>
    <string name="greeting_user">¡Hola, %1$s!</string>
    <string name="item_count">Tienes %1$d artículos en tu carrito por un total de %2$s.</string>
</resources>
```

---

## 4. Using Auto-Generated Strings in Code

When you build the project (`./gradlew build` or running the app), Compose Multiplatform automatically generates a type-safe `Res` object containing `Res.string.<string_name>`.

### A. Inside Composable UI Functions

Use `stringResource()` inside `@Composable` functions:

```kotlin
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import org.jetbrains.compose.resources.stringResource
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringArrayResource

// Import the auto-generated Res class
import com.yourpackage.app.generated.resources.Res
import com.yourpackage.app.generated.resources.welcome_message
import com.yourpackage.app.generated.resources.greeting_user
import com.yourpackage.app.generated.resources.action_checkout
import com.yourpackage.app.generated.resources.cart_items

@Composable
fun HomeScreen(userName: String, itemCount: Int) {
    // 1. Basic String Access
    Text(text = stringResource(Res.string.welcome_message))

    // 2. String with Dynamic Parameters
    Text(text = stringResource(Res.string.greeting_user, userName))

    // 3. Plurals Access
    Text(text = pluralStringResource(Res.plurals.cart_items, itemCount, itemCount))

    // 4. Action Button
    Button(onClick = { /* checkout logic */ }) {
        Text(text = stringResource(Res.string.action_checkout))
    }
}
```

### B. Outside Composables (ViewModels, Repositories, Async Functions)

For non-UI code or asynchronous operations, use `getString()` suspending function:

```kotlin
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.getString
import com.yourpackage.app.generated.resources.Res
import com.yourpackage.app.generated.resources.greeting_user

class NotificationService {
    suspend fun buildNotificationTitle(userName: String): String = withContext(Dispatchers.Default) {
        // getString is a suspend function that fetches the localized string based on active locale
        getString(Res.string.greeting_user, userName)
    }
}
```

---

## 5. Summary & Best Practices

1. **Native Integration**: Compose Multiplatform Resources works seamlessly across Android, iOS, Desktop (JVM), and Web (Wasm/JS).
2. **Type Safety**: Keys defined in XML automatically generate field properties on `Res.string`, catching typos and missing keys at compile time.
3. **Locale Support**: Follows standard Android qualifier conventions (`values-es`, `values-fr`, `values-ar`, `values-zh-rCN`, etc.).
4. **Build Performance**: Auto-generation occurs automatically during Gradle compilation, requiring no manual CLI script execution.
