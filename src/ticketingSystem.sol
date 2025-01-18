// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract TicketingSystem {
    struct artist {
        bytes32 name;
        uint256 artistCategory;
        address owner;
        uint256 totalTicketSold;
    }

    struct venue {
        bytes32 name;
        uint256 capacity;
        uint256 standardComission;
        address payable owner;
    }

    struct concert {
        uint256 artistId;
        uint256 venueId;
        uint256 concertDate;
        uint256 ticketPrice;
        bool validatedByArtist;
        bool validatedByVenue;
        uint256 totalSoldTicket;
        uint256 totalMoneyCollected;
    }

    struct ticket {
        uint256 concertId;
        address payable owner;
        bool isAvailable;
        bool isAvailableForSale;
        uint256 amountPaid;
    }

    uint256 public artistCount = 0;
    uint256 public venueCount = 0;
    uint256 public concertCount = 0;
    uint256 public ticketCount = 0;

    mapping(uint256 => artist) public artistsRegister;
    mapping(bytes32 => uint256) private artistsID;
    mapping(uint256 => venue) public venuesRegister;
    mapping(bytes32 => uint256) private venuesID;
    mapping(uint256 => concert) public concertsRegister;
    mapping(uint256 => ticket) public ticketsRegister;

    event CreatedArtist(bytes32 name, uint256 id);
    event ModifiedArtist(bytes32 name, uint256 id, address sender);
    event CreatedVenue(bytes32 name, uint256 id);
    event ModifiedVenue(bytes32 name, uint256 id);
    event CreatedConcert(uint256 concertDate, bytes32 name, uint256 id);

    constructor() {}

    function createArtist(bytes32 _name, uint256 _artistCategory) public {
        artistCount++;
        artist memory newArtist = artist({
            name: _name,
            artistCategory: _artistCategory,
            owner: msg.sender,
            totalTicketSold: 0
        });
        artistsRegister[artistCount] = newArtist;
        artistsID[_name] = artistCount;
        emit CreatedArtist(_name, artistCount);
    }

    function getArtistId(bytes32 _name) public view returns (uint256 ID) {
        require(artistsID[_name] != 0, "Artist does not exist");
        return artistsID[_name];
    }

    function modifyArtist(uint256 _artistId, bytes32 _name, uint256 _artistCategory, address payable _newOwner) public {
        require(_artistId <= artistCount && _artistId > 0, "Artist does not exist");
        require(msg.sender == artistsRegister[_artistId].owner, "not the owner");
        
        artistsRegister[_artistId].name = _name;
        artistsRegister[_artistId].artistCategory = _artistCategory;
        artistsRegister[_artistId].owner = _newOwner;
        artistsID[_name] = _artistId;
        emit ModifiedArtist(_name, _artistId, msg.sender);
    }

    function createVenue(bytes32 _name, uint256 _capacity, uint256 _standardComission) public {
        venueCount++;
        venue memory newVenue = venue({
            name: _name,
            capacity: _capacity,
            standardComission: _standardComission,
            owner: payable(msg.sender)
        });
        venuesRegister[venueCount] = newVenue;
        venuesID[_name] = venueCount;
        emit CreatedVenue(_name, venueCount);
    }

    function getVenueId(bytes32 _name) public view returns (uint256 ID) {
        require(venuesID[_name] != 0, "Venue does not exist");
        return venuesID[_name];
    }

    function modifyVenue(uint256 _venueId, bytes32 _name, uint256 _capacity, uint256 _standardComission, address payable _newOwner) public {
        require(_venueId <= venueCount && _venueId > 0, "Venue does not exist");
        require(msg.sender == venuesRegister[_venueId].owner, "not the venue owner");
        
        venuesRegister[_venueId].name = _name;
        venuesRegister[_venueId].capacity = _capacity;
        venuesRegister[_venueId].standardComission = _standardComission;
        venuesRegister[_venueId].owner = _newOwner;
        venuesID[_name] = _venueId;
        emit ModifiedVenue(_name, _venueId);
    }

    function createConcert(uint256 _artistId, uint256 _venueId, uint256 _concertDate, uint256 _ticketPrice) public {
        concertCount++;
        concert memory newConcert = concert({
            artistId: _artistId,
            venueId: _venueId,
            concertDate: _concertDate,
            ticketPrice: _ticketPrice,
            validatedByArtist: false,
            validatedByVenue: false,
            totalSoldTicket: 0,
            totalMoneyCollected: 0
        });
        
        if (msg.sender == artistsRegister[_artistId].owner) {
            newConcert.validatedByArtist = true;
        }
        
        concertsRegister[concertCount] = newConcert;
        emit CreatedConcert(_concertDate, artistsRegister[_artistId].name, concertCount);
    }

    function validateConcert(uint256 _concertId) public {
        require(_concertId <= concertCount && _concertId > 0, "Concert does not exist");
        concert storage concertToValidate = concertsRegister[_concertId];
        
        if (msg.sender == artistsRegister[concertToValidate.artistId].owner) {
            concertToValidate.validatedByArtist = true;
        } else if (msg.sender == venuesRegister[concertToValidate.venueId].owner) {
            concertToValidate.validatedByVenue = true;
        } else {
            revert("not authorized to validate");
        }
    }

    function emitTicket(uint256 _concertId, address payable _ticketOwner) public {
        require(_concertId <= concertCount && _concertId > 0, "Concert does not exist");
        concert storage concertToEmit = concertsRegister[_concertId];
        require(msg.sender == artistsRegister[concertToEmit.artistId].owner, "not the owner");
        
        ticketCount++;
        ticket memory newTicket = ticket({
            concertId: _concertId,
            owner: _ticketOwner,
            isAvailable: true,
            isAvailableForSale: false,
            amountPaid: 0
        });
        
        ticketsRegister[ticketCount] = newTicket;
        concertToEmit.totalSoldTicket++;
    }

    function useTicket(uint256 _ticketId) public {
        require(_ticketId <= ticketCount && _ticketId > 0, "Ticket does not exist");
        ticket storage ticketToUse = ticketsRegister[_ticketId];
        concert storage concertForTicket = concertsRegister[ticketToUse.concertId];
        
        require(msg.sender == ticketToUse.owner, "sender should be the owner");
        require(ticketToUse.isAvailable, "ticket already used");
        require(concertForTicket.validatedByVenue, "should be validated by the venue");
        require(
            block.timestamp <= concertForTicket.concertDate && 
            block.timestamp + 1 days > concertForTicket.concertDate, 
            "should be used the d-day"
        );
        
        ticketToUse.isAvailable = false;
        ticketToUse.owner = payable(address(0));
    }

    function buyTicket(uint256 _concertId) public payable {
        require(_concertId <= concertCount && _concertId > 0, "Concert does not exist");
        concert storage concertToBuy = concertsRegister[_concertId];
        require(msg.value >= concertToBuy.ticketPrice, "not enough funds");
        
        ticketCount++;
        ticket memory newTicket = ticket({
            concertId: _concertId,
            owner: payable(msg.sender),
            isAvailable: true,
            isAvailableForSale: false,
            amountPaid: concertToBuy.ticketPrice
        });
        
        ticketsRegister[ticketCount] = newTicket;
        concertToBuy.totalSoldTicket++;
        concertToBuy.totalMoneyCollected += msg.value;
    }

    function transferTicket(uint256 _ticketId, address payable _newOwner) public {
        require(_ticketId <= ticketCount && _ticketId > 0, "Ticket does not exist");
        ticket storage ticketToTransfer = ticketsRegister[_ticketId];
        require(msg.sender == ticketToTransfer.owner, "not the ticket owner");
        ticketToTransfer.owner = _newOwner;
    }

    function cashOutConcert(uint256 _concertId, address payable _cashOutAddress) public {
        require(_concertId <= concertCount && _concertId > 0, "Concert does not exist");
        concert storage concertToCashout = concertsRegister[_concertId];
        require(msg.sender == artistsRegister[concertToCashout.artistId].owner, "should be the artist");
        require(block.timestamp >= concertToCashout.concertDate, "should be after the concert");
        
        uint256 totalAmount = concertToCashout.totalMoneyCollected;
        uint256 venueShare = (totalAmount * venuesRegister[concertToCashout.venueId].standardComission) / 10000;
        uint256 artistShare = totalAmount - venueShare;
        
        artistsRegister[concertToCashout.artistId].totalTicketSold += concertToCashout.totalSoldTicket;
        
        (bool success1,) = venuesRegister[concertToCashout.venueId].owner.call{value: venueShare}("");
        require(success1, "Transfer to venue failed");
        
        (bool success2,) = _cashOutAddress.call{value: artistShare}("");
        require(success2, "Transfer to artist failed");
        
        concertToCashout.totalMoneyCollected = 0;
    }

    function offerTicketForSale(uint256 _ticketId, uint256 _salePrice) public {
        require(_ticketId <= ticketCount && _ticketId > 0, "Ticket does not exist");
        ticket storage ticketToSell = ticketsRegister[_ticketId];
        require(msg.sender == ticketToSell.owner, "should be the owner");
        require(_salePrice <= ticketToSell.amountPaid, "should be less than the amount paid");
        
        ticketToSell.isAvailableForSale = true;
        ticketToSell.amountPaid = _salePrice;
    }

    function buySecondHandTicket(uint256 _ticketId) public payable {
        require(_ticketId <= ticketCount && _ticketId > 0, "Ticket does not exist");
        ticket storage ticketToBuy = ticketsRegister[_ticketId];
        require(ticketToBuy.isAvailable, "should be available");
        require(ticketToBuy.isAvailableForSale, "should be available for sale");
        require(msg.value >= ticketToBuy.amountPaid, "not enough funds");
        
        address payable previousOwner = ticketToBuy.owner;
        ticketToBuy.owner = payable(msg.sender);
        ticketToBuy.isAvailableForSale = false;
        
        (bool success,) = previousOwner.call{value: msg.value}("");
        require(success, "Transfer failed");
    }
}
