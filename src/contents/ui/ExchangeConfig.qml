/**
 * Crypto Ticker widget for KDE
 *
 * @author    Marcin Orlowski <mail (#) marcinOrlowski (.) com>
 * @copyright 2021 Marcin Orlowski
 * @license   http://www.opensource.org/licenses/mit-license.php MIT
 * @link      https://github.com/MarcinOrlowski/crypto-plasmoid
 */

import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls
import org.kde.plasma.components 3.0 as PlasmaComponents
import "../js/crypto.js" as Crypto


ColumnLayout {
    Layout.fillWidth: true

    property bool running: true

    property string exchange: undefined
    property string crypto: undefined
    property string fiat: undefined
    property int refreshRate: 5
    property bool hidePriceDecimals: false

    property bool useCustomLocale: false
    property string customLocaleName: ''

    // ------------------------------------------------------------------------------------------------------------------------

    onExchangeChanged: {
        if (typeof exchange !== 'undefined') {
            exchangeComboBox.updateModel(exchange)

            cryptoComboBox.updateModel(exchange)
            // check if current value of crypto is supported by new exchange.
            // In such case fallback to first supported crypto.
            if (!Crypto.isCryptoSupported(exchange, crypto)) {
                var cryptos = getAllExchangeCryptos(exchange)
                crypto = cryptos[0]
            }
        } else {
            console.debug('exchange is undefined')
        }
    }

    onCryptoChanged: {
        if (typeof crypto !== 'undefined') {
            fiatComboBox.updateModel(exchange, crypto)
            if (!Crypto.isFiatSupported(exchange, crypto, fiat)) {
                var fiats = getFiatsForCrypto(exchange, crypto)
                fiat = fiats[0]
            }
        } else {
            console.debug('Invalid crypto name')
        }
    }

    // ------------------------------------------------------------------------------------------------------------------------

    CheckBox {
        text: i18n("Exchange enabled")
        checked: running
        onCheckedChanged: running = checked
    }

    // ------------------------------------------------------------------------------------------------------------------------

    Kirigami.FormLayout {
        enabled: running

        Layout.fillWidth: true

        PlasmaComponents.ComboBox {
            id: exchangeComboBox
            Kirigami.FormData.label: i18n('Exchange')
            textRole: "text"
            // Component.onCompleted: populateExchageModel()
            onCurrentIndexChanged: exchange = model[currentIndex]['value']

            function updateModel(exchange) {
                var tmp = []
                var idx = 0
                var currentIdx = undefined
                for(const key in Crypto.exchanges) {
                    tmp.push({'value': key, 'text': Crypto.getExchangeName(key)})
                    if (key === exchange) currentIdx = idx
                    idx++
                }
                model = tmp
                currentIndex = (typeof currentIdx !== 'undefined') ? currentIdx : 0
            }
        }

        // ------------------------------------------------------------------------------------------------------------------------

        PlasmaComponents.ComboBox {
            id: cryptoComboBox
            Kirigami.FormData.label: i18n('Crypto')
            textRole: "text"
            onCurrentIndexChanged: crypto = model[currentIndex]['value']

            function updateModel(exchange, crypto) {
                var tmp = []
                var currentIdx = undefined

                if (exchange in Crypto.exchanges) {
                    var tmp = Crypto.getAllExchangeCryptos(exchange);
                    var idx = 0
                    for (var i=0; i<tmp.length; i++) {
                        if (tmp[i].key == crypto) currentIdx = idx
                        idx++
                    }
                }

                model = tmp
                currentIndex = (typeof currentIdx !== 'undefined') ? currentIdx : 0
            }
        }

        // ------------------------------------------------------------------------------------------------------------------------

        PlasmaComponents.ComboBox {
            id: fiatComboBox
            Kirigami.FormData.label: i18n('Fiat')
            textRole: "text"
            onCurrentIndexChanged: fiat = model[currentIndex]['value']

            function updateModel(exchange, crypto) {
                var tmp = []
                var currentIdx = undefined

                if ((exchange in Crypto.exchanges) && (crypto in Crypto.exchanges[exchange]['pairs'])) {
                    tmp = Crypto.getFiatsForCrypto(exchange, crypto)

                    var idx = 0
                    for (var i=0; i<tmp.length; i++) {
                        if (tmp[i].key === fiat) currentIdx = idx
                        idx++
                    }
                }

                fiatComboBox.model = tmp
                fiatComboBox.currentIndex = (typeof currentIdx !== 'undefined') ? currentIdx : 0
            }
        }

        // ------------------------------------------------------------------------------------------------------------------------

        PlasmaComponents.SpinBox {
            editable: true
            from: 1
            to: 600
            stepSize: 15
            Kirigami.FormData.label: i18n("Update interval (minutes)")
            value: refreshRate
            onValueChanged: refreshRate = value
        }

        // FIXME should be per Pair as we may have i.e. LTCBTC pair soon
        // and this would make no sense then.
        PlasmaComponents.CheckBox {
            text: i18n("Hide price decimals")
            checked: hidePriceDecimals
            onCheckedChanged: hidePriceDecimals = checked
        }

        // ------------------------------------------------------------------------------------------------------------------------

        RowLayout {
            CheckBox {
                text: i18n("Locale to use")
                checked: useCustomLocale
                onCheckedChanged: useCustomLocale = checked
            }

            TextField {
                enabled: useCustomLocale
                placeholderText: "en_US"
                text: customLocaleName
                onTextChanged: customLocaleName = text
            }
        }

        // ------------------------------------------------------------------------------------------------------------------------

    }

    // ------------------------------------------------------------------------------------------------------------------------
}