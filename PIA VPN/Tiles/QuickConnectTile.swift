//
//  QuickConnectTile.swift
//  PIA VPN
//
//  Created by Jose Antonio Blaya Garcia on 10/01/2019.
//  Copyright © 2020 Private Internet Access, Inc.
//
//  This file is part of the Private Internet Access iOS Client.
//
//  The Private Internet Access iOS Client is free software: you can redistribute it and/or
//  modify it under the terms of the GNU General Public License as published by the Free
//  Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  The Private Internet Access iOS Client is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
//  details.
//
//  You should have received a copy of the GNU General Public License along with the Private
//  Internet Access iOS Client.  If not, see <https://www.gnu.org/licenses/>.

//

import UIKit
import PIALibrary

class QuickConnectTile: UIView, Tileable {

    private let maxElementsInArray = 6
    
    var view: UIView!
    var detailSegueIdentifier: String!
    var status: TileStatus = .normal {
        didSet {
            statusUpdated()
        }
    }
    
    @IBOutlet private weak var tileTitle: UILabel!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var labelsStackView: UIStackView!

    private var historicalServers: [Server] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.xibSetup()
        self.setupView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupView() {
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(viewShouldRestyle), name: .PIAThemeDidChange, object: nil)
        nc.addObserver(self, selector: #selector(updateQuickConnectList), name: .PIAServerHasBeenUpdated, object: nil)
        
        viewShouldRestyle()
        self.tileTitle.text = L10n.Tiles.Quick.Connect.title.uppercased()
        updateQuickConnectList()
        
    }
    
    @objc private func viewShouldRestyle() {
        tileTitle.style(style: TextStyle.textStyle21)
        Theme.current.applyPrincipalBackground(self)
    }
    
    @objc private func updateQuickConnectList() {
        
        historicalServers = Client.providers.serverProvider.historicalServers.filter { $0.serverNetwork == Client.configuration.currentServerNetwork() }
        for containerView in stackView.subviews {
            if let button = containerView.subviews.first as? ServerButton,
                let favoriteImage = containerView.subviews.last as? UIImageView {
                button.setImage(Theme.current.palette.appearance == .light ? Asset.Piax.Tiles.quickConnectPlaceholderLight.image :
                    Asset.Piax.Tiles.quickConnectPlaceholderDark.image, for: .normal)
                button.imageView?.contentMode = .scaleAspectFit
                button.isUserInteractionEnabled = false
                button.accessibilityLabel = L10n.Global.empty
                favoriteImage.isHidden = true
            }
        }
        
        for label in labelsStackView.subviews {
            if let label = label as? UILabel {
                label.text = ""
            }
        }
        
        let favoriteServers = Client.configuration.currentServerNetwork() == .gen4 ?
            AppPreferences.shared.favoriteServerIdentifiersGen4 :
            AppPreferences.shared.favoriteServerIdentifiers

        autocompleteRecentServers()
        
        for (index, server) in historicalServers.enumerated().reversed()  {
            let buttonIndex = historicalServers.count - (index + 1)
            let view = stackView.subviews[buttonIndex]
            if let button = view.subviews.first as? ServerButton,
                let favoriteImage = view.subviews.last as? UIImageView {
                button.alpha = 1
                button.setImage(fromServer: server)
                button.imageView?.contentMode = .scaleAspectFit
                button.isUserInteractionEnabled = true
                button.server = server
                button.accessibilityLabel = server.description
                favoriteImage.isHidden = !favoriteServers.contains(server.identifier)
                if status != .normal { //only when edit mode 
                    favoriteImage.isHidden = true
                }
            }
            
            if let label = labelsStackView.subviews[buttonIndex] as? UILabel {
                label.text = server.country
                Theme.current.applyCountryNameStyleFor(label)
            }

        }
    }
    
    private func autocompleteRecentServers() {
        var currentServers = Client.providers.serverProvider.currentServers.filter { $0.serverNetwork == Client.configuration.currentServerNetwork() }
        currentServers = currentServers.sorted(by: { $0.pingTime ?? 1000 < $1.pingTime ?? 1000 })
        currentServers = currentServers.filterDuplicate{ ($0.country) }

        let numberOfServersToAdd = maxElementsInArray - historicalServers.count

        if numberOfServersToAdd > 0 && currentServers.first?.pingTime != nil {
            let arraySlice = currentServers.prefix(numberOfServersToAdd)
            let newServersArray = Array(arraySlice)
            let currentHistorical = historicalServers
            historicalServers.removeAll()
            historicalServers.append(contentsOf: newServersArray.reversed())
            historicalServers.append(contentsOf: currentHistorical)
        }
        
    }
    
    @IBAction private func connectToServer(_ sender: ServerButton) {
        if Client.providers.vpnProvider.vpnStatus != .connecting,
            let server = sender.server {
            self.connectTo(server: server)
        }
    }

    private func statusUpdated() {
        updateQuickConnectList()
    }
    
}
