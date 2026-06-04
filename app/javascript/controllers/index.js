import { application } from "controllers/application"
import ClipboardController from "controllers/clipboard_controller"
import ExtensionBannerController from "controllers/extension_banner_controller"
import PasswordToggleController from "controllers/password_toggle_controller"

application.register("clipboard", ClipboardController)
application.register("extension-banner", ExtensionBannerController)
application.register("password-toggle", PasswordToggleController)
