var Layout = function(){
    var isRTL = false;
    var isIE8 = false;
    var isIE9 = false;
    var isIE10 = false;

    return {
        getViewPort: function() {
            var e = window,
                a = 'inner';
            if (!('innerWidth' in window)) {
                a = 'client';
                e = document.documentElement || document.body;
            }

            return {
                width: e[a + 'Width'],
                height: e[a + 'Height']
            };
        },
        // check IE8 mode
        isIE8: function() {
            return isIE8;
        },

        // check IE9 mode
        isIE9: function() {
            return isIE9;
        },

        //check RTL mode
        isRTL: function() {
            return isRTL;
        },
        scrollTo: function(el, offeset) {
            var pos = (el && el.size() > 0) ? el.offset().top : 0;

            if (el) {
                if ($('body').hasClass('page-header-fixed')) {
                    pos = pos - $('.page-header').height();
                }
                if ($('body').hasClass('fullheader-visible')) {
                    pos = pos - $('#fullheader').height();
                }
                pos = pos + (offeset ? offeset : -1 * el.height());
            }

            $('html,body').animate({
                scrollTop: pos
            }, 'slow');
        },
        getResponsiveBreakpoint: function(size) {
            // bootstrap responsive breakpoints
            var sizes = {
                'xs' : 480,     // extra small
                'sm' : 768,     // small
                'md' : 992,     // medium
                'lg' : 1200     // large
            };

            return sizes[size] ? sizes[size] : 0; 
        },
        initSlimScroll: function(el) {
            $(el).each(function() {
                if ($(this).attr("data-initialized")) {
                    return; // exit
                }

                var height;

                if ($(this).attr("data-height")) {
                    height = $(this).attr("data-height");
                } else {
                    height = $(this).css('height');
                }

                $(this).slimScroll({
                    allowPageScroll: true, // allow page scroll when the element scroll is ended
                    size: '7px',
                    color: ($(this).attr("data-handle-color") ? $(this).attr("data-handle-color") : '#bbb'),
                    wrapperClass: ($(this).attr("data-wrapper-class") ? $(this).attr("data-wrapper-class") : 'slimScrollDiv'),
                    railColor: ($(this).attr("data-rail-color") ? $(this).attr("data-rail-color") : '#eaeaea'),
                    position: isRTL ? 'left' : 'right',
                    height: height,
                    alwaysVisible: ($(this).attr("data-always-visible") == "1" ? true : false),
                    railVisible: ($(this).attr("data-rail-visible") == "1" ? true : false),
                    disableFadeOut: true
                });

                $(this).attr("data-initialized", "1");
            });
        },

        destroySlimScroll: function(el) {
            $(el).each(function() {
                if ($(this).attr("data-initialized") === "1") { // destroy existing instance before updating the height
                    $(this).removeAttr("data-initialized");
                    $(this).removeAttr("style");

                    var attrList = {};

                    // store the custom attribures so later we will reassign.
                    if ($(this).attr("data-handle-color")) {
                        attrList["data-handle-color"] = $(this).attr("data-handle-color");
                    }
                    if ($(this).attr("data-wrapper-class")) {
                        attrList["data-wrapper-class"] = $(this).attr("data-wrapper-class");
                    }
                    if ($(this).attr("data-rail-color")) {
                        attrList["data-rail-color"] = $(this).attr("data-rail-color");
                    }
                    if ($(this).attr("data-always-visible")) {
                        attrList["data-always-visible"] = $(this).attr("data-always-visible");
                    }
                    if ($(this).attr("data-rail-visible")) {
                        attrList["data-rail-visible"] = $(this).attr("data-rail-visible");
                    }

                    $(this).slimScroll({
                        wrapperClass: ($(this).attr("data-wrapper-class") ? $(this).attr("data-wrapper-class") : 'slimScrollDiv'),
                        destroy: true
                    });

                    var the = $(this);

                    // reassign custom attributes
                    $.each(attrList, function(key, value) {
                        the.attr(key, value);
                    });

                }
            });
        }
    }
}();
var Visor = function () {

	var doc_ident;
	var loading=$('.content-loading');
    var resBreakpointMd = Layout.getResponsiveBreakpoint('md');
    var sectionsList;

    // Hanles sidebar toggler
    var handleSidebarToggler = function () {
        var body = $('body');
        if ($.cookie && $.cookie('sidebar_closed') === '1' && Metronic.getViewPort().width >= resBreakpointMd) {
            $('body').addClass('page-sidebar-closed');
            $('.page-sidebar-menu').addClass('page-sidebar-menu-closed');
        }

        // handle sidebar show/hide
        $('body').on('click', '.sidebar-toggler', function (e) {
            var sidebar = $('.page-sidebar');
            var sidebarMenu = $('.page-sidebar-menu');
            $(".sidebar-search", sidebar).removeClass("open");

            if (body.hasClass("page-sidebar-closed")) {
                body.removeClass("page-sidebar-closed");
                sidebarMenu.removeClass("page-sidebar-menu-closed");
                if ($.cookie) {
                    $.cookie('sidebar_closed', '0');
                }
            } else {
                body.addClass("page-sidebar-closed");
                sidebarMenu.addClass("page-sidebar-menu-closed");
                if (body.hasClass("page-sidebar-fixed")) {
                    sidebarMenu.trigger("mouseleave");
                }
                if ($.cookie) {
                    $.cookie('sidebar_closed', '1');
                }
            }

            $(window).trigger('resize');
        });
        // handle content toggle
        $('body').on('click', '.page-content-toggler .expandall', function (e) {
            $('.panel-collapse').collapse('show');
        });
        $('body').on('click', '.page-content-toggler .collapseall', function (e) {
            $('.panel-collapse').collapse('hide');
        });
        
    };

    // Handles the go to top button at the footer
    var handleGoTop = function () {
        var offset = 300;
        var duration = 500;

        if (navigator.userAgent.match(/iPhone|iPad|iPod/i)) {  // ios supported
            $(window).bind("touchend touchcancel touchleave", function(e){
               if ($(this).scrollTop() > offset) {
                    $('.scroll-to-top').fadeIn(duration);
                } else {
                    $('.scroll-to-top').fadeOut(duration);
                }
            });
        } else {  // general 
            $(window).scroll(function() {
                if ($(this).scrollTop() > offset) {
                    $('.scroll-to-top').fadeIn(duration);
                } else {
                    $('.scroll-to-top').fadeOut(duration);
                }
            });
        }
        
        $('.scroll-to-top').click(function(e) {
            e.preventDefault();
            $('html, body').animate({scrollTop: 0}, duration);
            return false;
        });
    };
    // Handle links from sections to others sections
    var handleInterSectionLinks = function(){
        $('a[data-toggle="section"]').on('click',function(e){
            var ref= $(this).attr('href');
            $('.page-sidebar li > a[href="'+ref+'"]').trigger('click');
        });
    }
    // Handle sidebar menu
    var handleSidebarMenu = function() {
        $('.page-sidebar').on('click', 'li > a', function(e) {

            if (Layout.getViewPort().width >= resBreakpointMd && $(this).parents('.page-sidebar-menu-hover-submenu').size() === 1) { // exit of hover sidebar menu
                return;
            }

            if ($(this).next().hasClass('sub-menu') === false) {
                if (Layout.getViewPort().width < resBreakpointMd && $('.page-sidebar').hasClass("in")) { // close the menu on mobile view while laoding a page 
                    $('.page-header .responsive-toggler').click();
                }

                var target =  $(this).data('target') || $(this).attr('href');
                
                panel=$(target).find('.panel-collapse')

                if(panel && panel.size()){
                    if(panel.hasClass('collapse')) panel.collapse('show');
                }else{
                    $(target).closest('.panel-collapse').collapse('show');
                }
                
                $('.page-sidebar li').removeClass('active open');
                $(this).parent().addClass('active');
                if(Layout.getResponsiveBreakpoint('md') < $(window).outerWidth()){
                    /* Fixed header */
                    Layout.scrollTo($(target),-23);

                }else{
                    /* Relative header */
                    Layout.scrollTo($(target),50);
                }
                
                e.preventDefault();
                e.stopPropagation();

            }

            if ($(this).next().hasClass('sub-menu always-open')) {
                return;
            }


            var parent = $(this).parent().parent();
            var the = $(this);
            var menu = $('.page-sidebar-menu');
            var sub = $(this).next();

            var autoScroll = menu.data("auto-scroll");
            var slideSpeed = parseInt(menu.data("slide-speed"));
            var keepExpand = menu.data("keep-expanded");

            if (keepExpand !== true) {
                parent.children('li.open').children('a').children('.arrow').removeClass('open');
                parent.children('li.open').children('.sub-menu:not(.always-open)').slideUp(slideSpeed);
                parent.children('li.open').removeClass('open');
            }

            var slideOffeset = -200;

            if (sub.is(":visible")) {
                $('.arrow', $(this)).removeClass("open");
                $(this).parent().removeClass("open");
                sub.slideUp(slideSpeed, function() {
                    if (autoScroll === true && $('body').hasClass('page-sidebar-closed') === false) {
                        if ($('body').hasClass('page-sidebar-fixed')) {
                            menu.slimScroll({
                                'scrollTo': (the.position()).top
                            });
                        } else {
                            Layout.scrollTo(the, slideOffeset);
                        }
                    }
                });
            } else {
                $('.arrow', $(this)).addClass("open");
                $(this).parent().addClass("open");
                sub.slideDown(slideSpeed, function() {
                    if (autoScroll === true && $('body').hasClass('page-sidebar-closed') === false) {
                        if ($('body').hasClass('page-sidebar-fixed')) {
                            menu.slimScroll({
                                'scrollTo': (the.position()).top
                            });
                        } else {
                            Layout.scrollTo(the, slideOffeset);
                        }
                    }
                });
            }

            

            e.preventDefault();
        });
        $('.panel.section-info').on('mouseenter',function(e){
            e.preventDefault();
            e.stopPropagation();
            var href=$(this).attr('id');
            $('.page-sidebar li').removeClass('active open');
            $('a[href="#'+href+'"]').parent().addClass('active');
        })
        
    }
    var handleTopMenu = function(){

        // alert if it has addendum relationship
        if($('a[data-toogle="addendum"]').size()>0){
            var add=$('a[data-toogle="addendum"]');
                $.toaster({ priority : 'info','timeout'  : 9500, title : 'Title', message : "<a href='"+add.attr('href')+"'>This document has an addendum:<br><br><b>"+add.attr('title')+"</b><br>"+add.data('time')+"</a>"});
            }

        // handle search box expand/collapse        
        $('.page-header').on('click', '.search-form', function (e) {
            $(this).addClass("open");
            $(this).find('.form-control').focus();

            $('.page-header .search-form .form-control').on('blur', function (e) {
                $(this).closest('.search-form').removeClass("open");
                $(this).unbind("blur");
                $('#query_search').val('');
            });
        });
        $('.page-header .search-form').on('submit',function(){
            console.log('submit')
            e.preventDefault();
            e.stopPropagation();
            return false;
        })
        $('#query_search').bind('keyup change', function(ev) {
            // pull in the new value
            var searchTerm = $(this).val();

            // remove any old highlighted terms
            $('.panel-body').removeHighlight();

            // disable highlighting if empty
            if ( searchTerm ) {
                // highlight the new term
                $res=$('.panel-body').highlight( searchTerm );
                
                //open section match founded or close it
                if(searchTerm.length>3){
                    $res.each(function(){
                        if($(this).find('.highlight').size()>0){
                            $(this).parent().collapse('show');
                        } 
                        else $(this).parent().collapse('hide')
                        console.log(this);
                    })
                }
            }
        });
        

        // handle hor menu search form on enter press
        $('.page-header').on('keypress', '.hor-menu .search-form .form-control', function (e) {
            if (e.which == 13) {

                return false;
            }
        });

        // handle header search button click
        $('.page-header').on('mousedown', '.search-form.open .submit', function (e) {
            e.preventDefault();
            e.stopPropagation();

        });

        $('#collapseheader').on('shown.bs.collapse', function(e){
            //show;

            var h=$('#fullheader').outerHeight(true)

            
            Layout.scrollTo(0);

        }).on('hidden.bs.collapse', function(e){
           

            Layout.scrollTo(0);
        });

    }
    var handleSearch = function(query){
        console.log('Search');

        keys = query;
        matches = 0;

        //find matches in all sections
        for(c=0;c<keys.length;c++)
        {
            $('.panel-body').highlight(keys[c]);
        }
        matches = $('.panel-body .highlight').size();

        //if found it , call Toast notice
        if(matches>0){
            $.toaster({ priority : 'success','timeout'  : 9500, title : 'Title', message : "<a href='javascript:Visor.showSearch();'>This document has founded "+matches+" matches of keywords:<br> "+keys.toString()+"<br><b></b></a>"});
        }
    }


    // Helper function to calculate sidebar height for fixed sidebar layout.
    var _calculateFixedSidebarViewportHeight = function() {
        var sidebarHeight = Layout.getViewPort().height - $('.page-header').outerHeight() - 30;
        if ($('body').hasClass("page-footer-fixed")) {
            sidebarHeight = sidebarHeight - $('.page-footer').outerHeight();
        }

        return sidebarHeight;
    };
    // Handles fixed sidebar
    var handleFixedSidebar = function() {
        var menu = $('.page-sidebar-menu');

        Layout.destroySlimScroll(menu);

        if ($('.page-sidebar').size() === 0) {
            return;
        }

        if (Layout.getViewPort().width >= resBreakpointMd) {
            menu.attr("data-height", _calculateFixedSidebarViewportHeight());
            total_height=0;
            $('.page-sidebar-menu li').each(function(){
                total_height=total_height + $(this).height();
            })
            if(_calculateFixedSidebarViewportHeight()>total_height){
                $('body').removeClass('page-sidebar-fixed');
            }else{
                $('body').addClass('page-sidebar-fixed');
                Layout.initSlimScroll(menu);
            }
            
        }
    };
    // Handles sidebar toggler to close/hide the sidebar.
    var handleFixedSidebarHoverEffect = function () {
        var body = $('body');
        if (body.hasClass('page-sidebar-fixed')) {
            $('.page-sidebar').on('mouseenter', function () {
                if (body.hasClass('page-sidebar-closed')) {
                    $(this).find('.page-sidebar-menu').removeClass('page-sidebar-menu-closed');
                }
            }).on('mouseleave', function () {
                if (body.hasClass('page-sidebar-closed')) {
                    $(this).find('.page-sidebar-menu').addClass('page-sidebar-menu-closed');
                }
            });
        }
    };
	var iniVisor = function(ident,total){
         if ($('body').css('direction') === 'rtl') {
            isRTL = true;
        }

        isIE8 = !!navigator.userAgent.match(/MSIE 8.0/);
        isIE9 = !!navigator.userAgent.match(/MSIE 9.0/);
        isIE10 = !!navigator.userAgent.match(/MSIE 10.0/);

        if (isIE10) {
            $('html').addClass('ie10'); // detect IE10 version
        }

        if (isIE10 || isIE9 || isIE8) {
            $('html').addClass('ie'); // detect IE10 version
        }

        $('.tooltips').tooltip();


		doc_ident = ident;
		pages_total=total;
		$('.page-tab').click(function(){
			$(this).parent().find('.page-tab').removeClass('active');
			$(this).addClass('active');
			pageTabAction('num',$(this).attr('data-order'));
		});
		$('.quality-tab').click(function(){
			$(this).parent().find('.quality-tab').removeClass('active');
			$(this).addClass('active');
			qualityTabAction($(this).attr('data-ref'),$(this).attr('href'));
		})
		$('.page-next').click(function(){
			pageTabAction('ctr',1);
		});
		$('.page-prev').click(function(){
			pageTabAction('ctr',-1);
		});

	}



    var retrievePage = function(target,page,quality){
    	var $target = target;
    	loading.show();
      	$.ajax({
            cache: false,
            type: 'post',
            url: '/finder/getpdfpage',
            data: { ident: doc_ident, page: page, quality: quality},
            error: function(xhr, ajaxOptions, thrownError){

                loading.hide();
            },
            success: function(data, status) {
                $target.html(data);
                $target.removeClass('empty');
                loading.hide();
                // $('.modeview a[href="'+modoVista+'"]').tab('show');
            }
      });
    }
    var handleDicom = function() {

        if($('#12118112840100082164').size()>0){
            //create future frames for DICOM images
            menuDicom=$('li a[role="dicom"]').parent()
            menuDicom.find('>ul>li').each(function(e){
                var dicomName = $(this).find('>a .title').text() + " | "
                $(this).find('>ul>li').each(function(o){
                    var dicom2Name = dicomName + $(this).find('>a .title').text() + " | "
                    $(this).find('>ul>li').each(function(n){
                        var el = $(this).find('>a');
                        var title = dicom2Name + el.text()
                        var url = el.attr('href');
                        var ident = el.data('ident');
                        //create an iframe for each image
                        $('#12118112840100082164 .panel-body').first().append('<p><a id="'+ident+'" class="dicom-url section closed" href="'+url+'"><i class="fa"></i>&nbsp;'+title+'</a><iframe class="frame-dicom hidden" src="" width="100%" height="1024px"></iframe></p>');
                    
                    })
                })
            })
        }

        // Manage clicks in DICOM 's menu elements
        $('.dicom-url').click(function(e){
            e.preventDefault();
            e.stopPropagation();

            var el = $(this);
            if(el.hasClass('section')){
                if(el.hasClass('visited')){
                    if(el.hasClass('closed')){
                        el.removeClass('closed');
                    }else{
                        el.addClass('closed');
                    }
                    el.parent().find('iframe').toggle();
                }else{
                    el.parent().find('iframe').attr('src',el.attr('href')).removeClass('hidden');
                    el.addClass('visited').removeClass('closed');
                }
                
            }else{

                var target=$('#'+el.data('ident'))
                $(target).closest('.panel-collapse').collapse('show');
                Layout.scrollTo(target,-25);
                if(target.hasClass('closed')){
                    target.trigger('click');
                }
                
            }

        });
    }
    var handleSummary = function(sections){
        var sections = sections;

        $('body').on('click', '.page-content-toggler .summary', function (e) {
            
            $('.panel.section-info').each(function(){
                id = $(this).attr('id')
                hide = true;
                sections.forEach(function(a){
                    if(a==id){
                        hide = false;
                        
                    }
                });
                if(!hide){
                    $(this).find('.panel-collapse').collapse('show');
                }else{
                    $(this).find('.panel-collapse').collapse('hide');
                }
            })

        });
        $('.page-content-toggler .summary').trigger('click');
    }
    var handleTabs = function() {

        if (location.hash) {
            var tabid = location.hash.substr(1);
            $('a[href="#' + tabid + '"]').parents('.tab-pane:hidden').each(function() {
                var tabid = $(this).attr("id");
                $('a[href="#' + tabid + '"]').click();
            });
            $('a[href="#' + tabid + '"]').click();
        }
        $('a[data-toggle="tab"]').on('show.bs.tab', function (e) {
            window.location.hash = e.target.hash;
            Layout.scrollTo(0);
          });       
    }
    var handleWindow = function(){
        $('.tooltips').tooltip()
        var wh = $(window).height()
        var lh = $('.panel.section-info').last().height()
        $('.page-container').css('margin-bottom',(wh-lh-150));

        $(window).on('resize',function(){
            handleFixedSidebar();
        });
        

        $('#sidebar-menu').affix({
            offset: {
                top: function(g){

                        return ($('#fullheader').outerHeight(true))
                }
              }
        });

    }

    return {
    	init: function (ident,total_pages) {
            handleFixedSidebar();
            handleFixedSidebarHoverEffect();
            handleSidebarMenu();
    		handleDicom();
            handleTabs();
            handleSidebarToggler();
            handleGoTop();
            handleTopMenu();
            handleInterSectionLinks();
            handleWindow();
            
        },
        summary: function(sections){
            handleSummary(sections);
        },
        search: function(query){
            handleSearch(query);
        },
        showSearch: function(){
            $('.panel-body').each(function(){
                if($(this).find('.highlight').size() > 0){
                   $(this).parent().collapse('show');
                }
                else{
                     $(this).parent().collapse('hide');
                }
            })
        }
        
    };
}();
