// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BoredDrink is ERC721, ERC721Enumerable, Pausable, Ownable {
    uint256 public allowListPrice = 0.001 ether; //Setando valor de mint (para o allowListMint)
    uint256 public publicMintPrice = 0.02 ether; //Setando valor de mint (para o publicMint)
    uint256 public maxSupply = 50; //Setando um supply máximo de NFTS
    uint256 public maxPerWallet = 2; //Setando quantida máxima de nft mintadas
    bool public allowListMintOpen; //Por padrão um bool é false (para manter o allowList fechado) 
    bool public publicMintOpen; //Por padrão um bool é false (para manter o publicMint fechado)
    mapping(address => bool) public allowList; //Irá mapear o endereço para ver se está na lista
    mapping(address => uint256) public walletMints; //Mapeando o address para ver quantos nfts ele tem

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("RABBIT MONSTERS", "R-MONS") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://metadata.json";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    

    //Adicionando função para permitir que apenas usuários de uma lista possa mintar
    //Ao chamar a função, ela percorre por cada require
    function allowListMint(uint256 quantity_) public payable  {
        require(allowList[msg.sender], "Voce nao esta na lista"); //Tem que ser true, se não mostre a mensagem
        require(allowListMintOpen, "allowListMint esta fechada"); //Se allowList for false, não poderá mintar
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, "Exceed max Wallet"); //walletMints vai fazer um mapping no msg.sender
        require(msg.value == quantity_ * allowListPrice, "Fundos insuficiente!"); //Calculando que o sender tem que pagar para mintar

        for (uint256 i = 0; i < quantity_; i++) {
            walletMints[msg.sender] += 1;
            internalMint(); //Função de Clean Code, aqui teria mais linhas, mas foi removidas
           }
    }
    
    //public = qualquer um que interagir com o contrato pode chamar a função mint
    //payable = para mintar tem que pagar
    //require = condição = o valor que o msg.sender tem que mandar tem que ser igual a 0.02 ether
    function publicMint(uint256 quantity_) public payable  {
        require(publicMintOpen, "publicMint Closed");
        require(totalSupply() + quantity_ < maxSupply, "We sold out!");//A extensão Enumerable já vem com a função totalSupply()
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, "Exceed max Wallet");
        require(msg.value == quantity_ * publicMintPrice, "Fundos insuficiente!");

        for (uint256 i = 0; i < quantity_; i++) {
            walletMints[msg.sender] += 1;
            internalMint(); //Função de Clean Code aqui teria mais linhas mas foi removidas
           }
    }
    

    /*Função onde apenas o owner do contrato pode modificar os valores dos boleanos allowListMintOpen e 
    publicMintOpen para liberar a mintagem */
    function editMintWindows(bool _allowListMintOpen, bool _publicMintOpen) external onlyOwner {
        allowListMintOpen = _allowListMintOpen;
        publicMintOpen = _publicMintOpen;
    }
    

    /*Aqui é feito uma iteração no array do address para verificar seu endereço, e que retorna allowList como true
    depois tenho que passar allowList em um require dentro da função de mint do AllowListMint */
    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++)
        {
            allowList[addresses[i]] = true;
        }

    }

    //Função de saque, onde apenas o owner do contrato pode retirar fundos
    function withdraw(address _addr) external onlyOwner {
        uint256 balance = address(this).balance;
        payable (_addr).transfer(balance);
    }

    //Função adicional para fazer um Up clean code, removendo algumas coisas repetidas e add a uma função
    function internalMint() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}