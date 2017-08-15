//
//  CollectionViewController.swift
//  CardCollectionView
//
//  Created by Alexander Lovato on 1/18/17.
//  Copyright © 2017 Nonsense. All rights reserved.
//

import UIKit

class CardCollectionViewController: UICollectionViewController {
    
    
    
    /// The pan gesture will be used for this scroll view so the collection view can page items smaller than it's width
    lazy var pagingScrollView: UIScrollView = { [unowned self] in
        let scrollView = UIScrollView()
        scrollView.isHidden = true
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        return scrollView
    }()
    
    /// Layer used for styling the background view
    private lazy var backgroundGradientLayer: CAGradientLayer = { [unowned self] in
        let gradient = CAGradientLayer()
        gradient.frame = self.view.bounds
        gradient.startPoint = CGPoint.zero
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.colors = [
            UIColor(hue: 214/360, saturation: 4/100, brightness: 44/100, alpha: 1).cgColor,
            UIColor(hue: 240/360, saturation: 14/100, brightness: 17/100, alpha: 1).cgColor
        ]
        return gradient
    }()
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // inset collection view left/right-most cards can be centered
        let flowLayout = getFlowLayout()
        let edgePadding = (self.collectionView!.bounds.size.width - flowLayout.itemSize.width)/2
        self.collectionView!.contentInset = UIEdgeInsets(top: 0, left: edgePadding, bottom: 0, right: edgePadding)
        
        // style
        self.collectionView?.backgroundView = {
            let view = UIView(frame: self.view.bounds)
            view.layer.addSublayer(self.backgroundGradientLayer)
            return view
        }()
        
        // Register cell classes
        self.collectionView!.register(CardCollectionViewCell.self, forCellWithReuseIdentifier: CardCollectionViewCellConst.reuseId)
        
        // add scroll view which we'll hijack scrolling from
        
        pagingScrollView.frame = scrollViewFrameSize()
        pagingScrollView.contentSize = setScrollViewContentSize()
        self.collectionView!.superview!.insertSubview(pagingScrollView, belowSubview: self.collectionView!)
        self.collectionView!.addGestureRecognizer(pagingScrollView.panGestureRecognizer)

        self.collectionView?.isScrollEnabled = false
//        self.collectionView?.isPagingEnabled = true
        
        
        //Swipe up to enable deleting calculators
        //TODO: - Need to find a way to extend the length of the gesture in the swipe
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeToDelete(sender:)))
        upSwipe.direction = UISwipeGestureRecognizerDirection.up
        self.collectionView!.addGestureRecognizer(upSwipe)
        
        
        // Automatically create and transition into a new calculator is there aren't any
        if CalculatorController.sharedController.calculators.count == 0 {
            let calculator = Calculator(currentNumber: "0", operationStack: [], entireOperationString: [], currentlyTypingNumber: false, screenshotData: Data())
            CalculatorController.sharedController.saveCalculatorTab(calculatorTab: calculator)
            collectionView?.reloadData()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CalculatorViewController") as! CalculatorViewController
            let cardIndex = CalculatorController.sharedController.calculators.first!
            vc.calculator = cardIndex
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        collectionView?.remembersLastFocusedIndexPath = true
        self.restoresFocusAfterTransition = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.collectionView?.reloadData()
        
    }
    

    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = self.view.bounds
    }
    
    // MARK: - Status Bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func scrollViewFrameSize() -> CGRect {
        let flowLayout = getFlowLayout()
        
        let frame = CGRect(
            x: self.view.bounds.width,
            y: 0,
            width: flowLayout.itemSize.width,
            height: self.view.bounds.height)
        return frame
    }
    
    func getFlowLayout() -> UICollectionViewFlowLayout {
        let flowLayout = self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        return flowLayout
    }
    
    func setScrollViewContentSize() -> CGSize {
        let cellCount = CGFloat(CalculatorController.sharedController.calculators.count)
        let contentSize = CGSize(width: getFlowLayout().itemSize.width*cellCount, height: self.view.bounds.height)
        return contentSize
    }
    
    // MARK: - Delete Cell Functions
    
    func swipeToDelete(sender: UISwipeGestureRecognizer) {
        
        if CalculatorController.sharedController.calculators.count != 1 {
            
            collectionView?.performBatchUpdates({
                guard let indexPath = self.centeredIndexPath() else { return }
                let calculator = CalculatorController.sharedController.calculators[indexPath.item]
                CalculatorController.sharedController.deleteCalculator(calculator: calculator)
                self.collectionView?.deleteItems(at: [indexPath])

            }, completion: { (true) in
                
                self.pagingScrollView.contentSize = self.setScrollViewContentSize()
                self.collectionView?.reloadData()
                
            })
        }
    }


    @IBAction func addNewCalculatorButtonTapped(_ sender: UIBarButtonItem) {
        
        self.collectionView?.performBatchUpdates({
            let defaultPhoto = UIImagePNGRepresentation(#imageLiteral(resourceName: "DefaultCell"))
            let calculator = Calculator(currentNumber: "0", operationStack: [], entireOperationString: [], currentlyTypingNumber: false, screenshotData: defaultPhoto)
            CalculatorController.sharedController.saveCalculatorTab(calculatorTab: calculator)
            let count = CalculatorController.sharedController.calculators.count
            let insertedIndexPath = IndexPath(item: count-1, section: 0)
            self.collectionView?.insertItems(at: [insertedIndexPath])
            
        }, completion: { (true) in
            self.pagingScrollView.contentSize = self.setScrollViewContentSize()
            self.collectionView?.reloadData()
            
            //Scroll to last Calculator cell
            let cellCount = CGFloat(CalculatorController.sharedController.calculators.count) - 1
            let frameSize = self.getFlowLayout().itemSize.width*cellCount
            let point = CGPoint(x: frameSize, y: 0)
            self.pagingScrollView.setContentOffset(point, animated: true)
            
            
            //Select the new calcuator cell
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CalculatorViewController") as! CalculatorViewController
            let calculator = CalculatorController.sharedController.calculators.last!
            
            
            vc.calculator = calculator
            self.navigationController?.pushViewController(vc, animated: true)
            
            
        })
    }
    
//    func scrollToLastAddedCellAnimated(_ animated: Bool) {
//        let count = CalculatorController.sharedController.calculators.count
//        if count > 0 {
//            self.collectionView?.scrollToItem(at: IndexPath(item: count-1, section: 0), at: .right, animated: animated)
//            
//        }
//    }
}




// MARK: - Collection View Delegate

extension CardCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CalculatorViewController") as! CalculatorViewController
        let cardIndex = CalculatorController.sharedController.calculators[indexPath.item]
        
        vc.calculator = cardIndex
        self.navigationController?.pushViewController(vc, animated: true)
    }
}


// MARK: - Collection View Datasource

extension CardCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CalculatorController.sharedController.calculators.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CardCollectionViewCellConst.reuseId, for: indexPath) as! CardCollectionViewCell
        let calculatorIndex = CalculatorController.sharedController.calculators[indexPath.item]
        let screenshotImage = calculatorIndex.screenshotImage
        cell.imageView.image = screenshotImage
        
        return cell
    }
}


// MARK: - Scroll Delegate

extension CardCollectionViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === pagingScrollView {
            // adjust collection view scroll view to match paging scroll view
            let contentOffset = CGPoint(x: scrollView.contentOffset.x - self.collectionView!.contentInset.left,
                                        y: self.collectionView!.contentOffset.y)
            self.collectionView!.contentOffset = contentOffset
        }
    }
}


// MARK: - Transition Delegate

extension CardCollectionViewController: CardToDetailViewAnimating {
    
    // returns index path at center of screen (if there is one)
    func centeredIndexPath() -> IndexPath? {
        guard let collectionView = self.collectionView else { return nil }
        let centerPoint = CGPoint(x: collectionView.contentOffset.x + self.view.bounds.midX,
                                  y: collectionView.bounds.midY)
        return collectionView.indexPathForItem(at: centerPoint)
    }
    // returns cell at center of screen (if there is one)
    func centeredCell() -> UICollectionViewCell? {
        guard let collectionView = self.collectionView else { return nil }
        if let indexPath = centeredIndexPath() {
            return collectionView.cellForItem(at: indexPath)
        } else {
            return nil
        }
    }
    
    
    
    func viewForTransition() -> UICollectionViewCell {
        //TODO: - Reset to original config once cell images start working
        guard let cell = centeredCell() else { return UICollectionViewCell() }
        
        // I can hide the cell when returning to collectionView but unable to unhide the cell
//        cell.isHidden = true
//        let mainQueue = DispatchQueue.main
//        let deadline = DispatchTime.now() + .milliseconds(1300)
//        mainQueue.asyncAfter(deadline: deadline) {
//            cell.isHidden = false
//            
//        }
        
        return cell
    }
    func beginFrameForTransition() -> CGRect {
        guard let indexPath = centeredIndexPath() else { fatalError("this transition should never exist w/o starting index path") }
        guard let attributes = self.collectionView!.collectionViewLayout.layoutAttributesForItem(at: indexPath) else { fatalError("layout is not returning attributes for path: \(indexPath)") }
        // get frame of centered cell, converting to window coordinates
        var frame = attributes.frame
        frame.origin.x -= self.collectionView!.contentOffset.x
        frame.origin.y += self.topLayoutGuide.length + CardLayoutConst.maxYOffset
        return frame
    }
}
