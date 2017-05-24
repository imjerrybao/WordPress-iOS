import UIKit
import WordPressShared

/// A stylized button used by Login controllers. It also can display a `UIActivityIndicatorView`.
@objc class LoginButton: NUXSubmitButton {

    // MARK: - Configuration

    /// Configure the appearance of the configure button.
    override func configureButton() {
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)

        titleLabel?.font = WPFontManager.systemSemiBoldFont(ofSize: 17.0)

        let normalImage: UIImage?
        let highlightImage: UIImage?
        let titleColorNormal: UIColor
        if isPrimary {
            normalImage = UIImage(named: "beveled-blue-button")
            highlightImage = UIImage(named: "beveled-blue-button-down")

            titleColorNormal = UIColor.white
        } else {
            normalImage = UIImage(named: "beveled-secondary-button")
            highlightImage = UIImage(named: "beveled-secondary-button-down")

            titleColorNormal = WPStyleGuide.darkGrey()
        }
        let disabledImage = UIImage(named: "beveled-disabled-button")
        let titleColorDisabled = WPStyleGuide.greyLighten30()


        setBackgroundImage(normalImage, for: .normal)
        setBackgroundImage(highlightImage, for: .highlighted)
        setBackgroundImage(disabledImage, for: .disabled)

        setTitleColor(titleColorNormal, for: .normal)
        setTitleColor(titleColorNormal, for: .highlighted)
        setTitleColor(titleColorDisabled, for: .disabled)

        addSubview(activityIndicator)
    }

    override func configureBorderColor() {
        configureButton()
    }
}
