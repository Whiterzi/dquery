part of dquery;

void _cleanData(Element element) {
  for (Element c in element.children) {
    if (!_dataPriv.hasData(c))
      continue;
    final Map space = _dataPriv.getSpace(c);
    // remove event handlers
    if (space.containsKey('events'))
      for (String type in (space['events'] as Map).keys)
        _EventUtil.remove(c, type, null, null);
    
    _dataPriv.discard(c);
    _cleanData(c);
  }
}

void _detach(Element elem, bool data) {
  if (data)
    _cleanData(elem);
  
  if (elem.parent != null) {
    /*
    if ( keepData && jQuery.contains( elem.ownerDocument, elem ) ) {
      setGlobalEval( getAll( elem, "script" ) );
    }
    */
    elem.remove();
  }
}

void _empty(Element elem) {
  for (Element c in elem.children)
    _cleanData(c);
  elem.nodes.clear();
}

ElementQuery? _resolveManipTarget(target) =>
    target is ElementQuery ? target :
    target is String || target is Element ? $(target) : null;

ElementQuery? _resolveManipContent(value) =>
    value is ElementQuery ? value : 
    value is Element ? $(value) :
    value is String && value.startsWith('<') ? $(value) : null; // TODO: function later

void _domManip(ElementQuery? refs, content, void f(Element ref, ElementQuery obj)) {
  if (refs?.isEmpty ?? true)
    return;
  
  final objs = _resolveManipContent(content);
  if (objs?.isEmpty ?? true)
    return;
  
  final last = refs!.last;
  for (final n in refs)
    f(n, n == last ? objs! : objs!.clone());
  
}

void _appendFunc(Element ref, ElementQuery obj) =>
    obj.forEach((Element elem) => ref.append(elem));

void _prependFunc(Element ref, ElementQuery obj) {
  final before = ref.hasChildNodes() ? ref.nodes.first : null;
  obj.forEach((Element elem) => ref.insertBefore(elem, before));
}

void _afterFunc(Element ref, ElementQuery obj) {
  final parent = ref.parentNode as Node,
    before = ref.nextNode;
  obj.forEach((Element elem) => parent.insertBefore(elem, before));
}

void _beforeFunc(Element ref, ElementQuery obj) {
  final parent = ref.parentNode as Node;
  obj.forEach((Element elem) => parent.insertBefore(elem, ref));
}

Element _clone(Element elem, [bool dataAndEvents = false, bool? deepDataAndEvents]) {
  if (deepDataAndEvents == null)
    deepDataAndEvents = dataAndEvents;
  
  final clone = elem.clone(true) as Element; // deep
  
  //inPage = jQuery.contains( elem.ownerDocument, elem );
  
  // skipped for now
  // jQuery: Support: IE >= 9
  //         Fix Cloning issues
  /*
  if ( !jQuery.support.noCloneChecked && ( elem.nodeType === 1 || elem.nodeType === 11 ) && !jQuery.isXMLDoc( elem ) ) {
    // jQuery: We eschew Sizzle here for performance reasons: http://jsperf.com/getall-vs-sizzle/2
    destElements = getAll( clone );
    srcElements = getAll( elem );
    for ( i = 0, l = srcElements.length; i < l; i++ )
      fixInput( srcElements[ i ], destElements[ i ] );
  }
  */
  
  // jQuery: Copy the events from the original to the clone
  if (dataAndEvents)
    _cloneCopyEvent(elem, clone, deepDataAndEvents);
  
  // skipped for now
  // jQuery: Preserve script evaluation history
  /*
  destElements = getAll( clone, "script" );
  if ( destElements.length > 0 ) {
    setGlobalEval( destElements, !inPage && getAll( elem, "script" ) );
  }
  */
  
  // Return the cloned set
  return clone;

}

void _cloneCopyEvent(Element src, Element dest, [bool deep = false]) {
  
  // jQuery: 1. Copy private data: events, handlers, etc.
  if (_dataPriv.hasData(src)) {
    final pdataOld = _dataPriv.getSpace(src);
    final pdataCur = _dataPriv.getSpace(dest);
    pdataOld.forEach((String k, v) {
      if (k != 'events')
        pdataCur[k] = v;
    });
    
    final events = pdataOld['events'];
    if (events != null && !events.isEmpty) {
      events.forEach((String type, _HandleObjectContext hoc) {
        for (_HandleObject h in hoc.handlers)
          _EventUtil.add(dest, type, h.handler, h.selector);
        for (_HandleObject h in hoc.delegates)
          _EventUtil.add(dest, type, h.handler, h.selector);
      });
    }
  }
  
  // jQuery: 2. Copy user data
  if (_dataUser.hasData(src))
    _dataUser.setAll(dest, _dataUser.getSpace(src));
  
  // unlike jQuery, we do deep clone by recursion
  if (deep) {
    int i = 0;
    for (Element c in src.children)
      _cloneCopyEvent(c, dest.children[i++], true);
  }
  
}



void _setText(Element elem, String value) {
  elem.children.clear();
  elem.append(new Text(value));
}

// in strong type system, no way to get to text node or document fragment
/*
String _getText(Node node) =>
    node is Element ? (node as Element).text :
    node is Document ? (node as Document).text :
    node is DocumentFragment ? (node as DocumentFragment).text :
    node is Text ? node.nodeValue : '';
*/