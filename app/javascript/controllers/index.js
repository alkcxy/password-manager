import { application } from "controllers/application"
import ClipboardController from "controllers/clipboard_controller"
import PasswordToggleController from "controllers/password_toggle_controller"

application.register("clipboard", ClipboardController)
application.register("password-toggle", PasswordToggleController)
